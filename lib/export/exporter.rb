# frozen_string_literal: true

require 'csv'
require 'bagit'
require 'aws-sdk-s3'
require 'active_support'
require 'active_support/time'
ENV["TZ"] = "US/Eastern"

BAG_STATUSES = { 'not_bagged' => 0, 'bagged' => 1, 'bagging_failed' => 3 } .freeze
S3_STATUSES = { 'not_uploaded' => 0, 'uploaded' => 1, 'upload_failed' => 3 }.freeze
APT_STATUSES = { 'not_checked' => 0, 'confirmed' => 1, 'pending' => 3, 'failed' => 4, 'not_found' => 5, 'bad_aptrust_response_code' => 6 }.freeze

module Export
  class Exporter
    attr_reader :all_metadata, :monograph, :monograph_presenter, :columns, :aptrust

    def initialize(monograph_id, columns = :all)
      @monograph = Sighrax.factory(monograph_id)
      @columns = columns
      #  Use aws credentials for atrust
      filename = Rails.root.join('config', 'aptrust.yml')
      yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
      @aptrust = yaml || nil
    end

    def export_bag # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      ## create bag directory with valid, noid-based aptrust name

      if monograph_presenter.subdomain.to_s.blank?
        apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'check on press', 'fail', "In Exporter.rb export_bag, monograph_presenter.press is blank!")
        return
      end

      bag_name = "fulcrum.org.#{monograph_presenter.subdomain}-#{monograph_presenter.id}"

      bag_pathname = "#{Settings.aptrust_bags_path}/#{bag_name}"

      # On the first run these shouldn't be needed but...
      # clean up old bag and tar files
      FileUtils.rm_rf(bag_pathname) if File.exist?(bag_pathname)
      FileUtils.rm_rf("#{bag_pathname}.tar") if File.exist?("#{bag_pathname}.tar")

      apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'pre-bag', 'okay', 'About to make bag')

      FileUtils.mkdir_p(Settings.aptrust_bags_path) unless Dir.exist?(Settings.aptrust_bags_path)

      bag = BagIt::Bag.new bag_pathname

      # add bagit-info.txt file
      timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      bag.write_bag_info(
        'Source-Organization' => 'University of Michigan',
        'Bag-Count' => '1',
        'Bagging-Date' => timestamp
      )

      # Add aptrust-info.txt file
      # this is text that shows up in the APTrust web interface
      # title, access, and description are required; Storage-Option defaults to Standard if not present
      File.open(File.join(bag.bag_dir, 'aptrust-info.txt'), "w") do |io|
        ti = monograph_presenter.title.blank? ? '' : monograph_presenter.title.first.squish[0..255]
        io.puts "Title: #{ti}"
        io.puts "Access: Institution"
        io.puts "Storage-Option: Standard"
        io.puts "Description: This bag contains all of the data and metadata related to a Monograph which has been exported from the Fulcrum publishing platform hosted at https://www.fulcrum.org. The data folder contains a Fulcrum manifest in the form of a CSV file named with the NOID assigned to this Monograph in the Fulcrum repository. This manifest is exported directly from Fulcrum's heliotrope application (https://github.com/mlibrary/heliotrope) and can be used for re-import as well. The first two rows contain column headers and human-readable field descriptions, respectively. {{ The final row contains descriptive metadata for the Monograph; other rows contain metadata for Assets, which may be components of the Monograph or material supplemental to it.}}"
        pub = monograph_presenter.publisher.blank? ? '' : monograph_presenter.publisher.first.squish[0..249]
        io.puts "Press-Name: #{pub}"
        pr = monograph_presenter.press.blank? ? '' : monograph_presenter.press.squish[0..249]
        io.puts "Press: #{pr}"
        # 'Item Description' may be helpful when looking at Pharos web UI
        ides = monograph_presenter.description.blank? ? '' : monograph_presenter.description.first.squish[0..249]
        io.puts "Item Description: #{ides}"
        creat = monograph_presenter.creator.blank? ? '' : monograph_presenter.creator.first.squish[0..249]
        io.puts "Creator/Author: #{creat}"
      end

      # put fulcrum files into data directory
      extract("#{bag.bag_dir}/data/")

      # Create manifests
      bag.manifest!

      # Make sure the bag is valid before proceeding
      record = AptrustUpload.find_by!(noid: monograph_presenter.id)
      if bag.valid?
        apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'bag validation', 'okay', "Current bag is valid in lib/export/exporter.rb")
        record.update!(
          bag_status: BAG_STATUSES['bagged']
        )
        puts "Bag is valid"  
      else
        apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'bag validation', 'error', "Current bag is not valid in lib/export/exporter.rb")
        record.update!(
          bag_status: BAG_STATUSES['bagging_failed'],
          s3_status: S3_STATUSES['not_uploaded'],
          apt_status: APT_STATUSES['not_checked']
        )
        puts "bag is NOT valid"
      end

      # Tar and remove bag directory
      # but first change to the aptrust-bags directory
      restore_dir = Dir.pwd
      Dir.chdir(Settings.aptrust_bags_path)

      begin
        Minitar.pack(bag_name, File.open("#{bag_name}.tar", 'wb'))
      rescue StandardError => error
        apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'tarring', 'error', "Error for Minitar in lib/export/exporter.rb: #{error}")
      end

      # Upload the bag to the s3 bucket (umich A&E test bucket for now)
      uploaded = send_to_s3("#{bag_name}.tar")

      # Update AptrustUploads database if bag is processed
      if uploaded
        update_aptrust_db(true)
        apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'post-upload', 'okay', 'Upload success')
      else
        update_aptrust_db(false)
        apt_log(monograph_presenter.id.to_s, 'exporter - export_bag', 'post-upload', 'error', "APTRUST: Upload failed for #{bag_pathname}.tar.")
      end

      # Remove the bag_dir and tarred bag
      FileUtils.rm_rf(bag_name)
      FileUtils.rm_rf("#{bag_name}.tar")

      # Now restore the previous directory
      Dir.chdir(restore_dir)
    end

    def export
      return String.new if monograph.instance_of?(Sighrax::NullEntity)

      rows = []
      monograph.children.each do |member|
        member_presenter = Sighrax.hyrax_presenter(member)
        rows << metadata_row(member_presenter, monograph_presenter.representative_id)
      end

      rows << metadata_row(monograph_presenter)
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
        rows.each { |row| csv << row if row.present? }
      end

      buffer
    end

    def extract(use_dir = nil, now = false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return unless monograph.valid?

      job_path = nil

      if use_dir
        path = "#{use_dir}/"
        job_path = if path[0] == '/'
                     path
                   else
                     File.join(Dir.pwd, path)
                   end
      else
        base = File.join(".", "extract")
        FileUtils.mkdir(base) unless Dir.exist?(base)
        press = File.join(base, monograph_presenter.subdomain.to_s)
        FileUtils.mkdir(press) unless Dir.exist?(press)
        path = File.join(press, monograph.noid.to_s)
        if Dir.exist?(path)
          puts "Overwrite #{path} directory? (Y/n):"
          return unless /y/i.match?(STDIN.getch)

          FileUtils.rm_rf(path)
        end
        FileUtils.mkdir(path)
        job_path = File.join(Dir.pwd, path)
      end

      manifest = File.new(File.join(path, monograph.noid.to_s + ".csv"), "w")
      manifest << export
      manifest.close

      if now
        OutputMonographFilesJob.perform_now(monograph.noid, job_path)
      else
        OutputMonographFilesJob.perform_later(monograph.noid, job_path)
      end
    end

    def monograph_row
      metadata_row(monograph)
    end

    def blank_csv_sheet
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
      end
      buffer
    end

    def write_csv_header_rows(csv)
      row1 = []
      row2 = []
      all_metadata.each do |field|
        row1 << field[:field_name]
        # don't want to deal with the huge instruction/description fields in test
        row2 << (Rails.env.test? ? 'instruction placeholder' : field[:description])
      end
      csv << row1 << row2
    end

    def send_to_s3(file)
      Aws.config.update(
        credentials: Aws::Credentials.new(@aptrust['AwsAccessKeyId'], @aptrust['AwsSecretAccessKey'])
      )

      # Set s3 with a region
      s3 = Aws::S3::Resource.new(region: @aptrust['BucketRegion'])

      # Get the aptrust test bucket by name
      bucket_name = @aptrust['Bucket']
      fulcrum_bucket = s3.bucket(bucket_name)

      # Get just the file name
      name = File.basename(file)

      # Check if file is already in the bucket
      msg = fulcrum_bucket.object(name).exists? ? "bag #{name} already exists in the s3 bucket: #{bucket_name} overwriting bag!" : "creating a brand new bag for #{name} in s3 bucket: #{bucket_name}"
      apt_log(monograph_presenter.id.to_s, 'exporter - send_to_s3', 'pre-upload', 'okay', msg)
      begin
        # Create the object to upload and upload it
        obj = s3.bucket(bucket_name).object(name)
        obj.upload_file(file)
        success = true
      rescue Aws::S3::Errors::ServiceError
        apt_log(monograph_presenter.id.to_s, 'exporter - send_to_s3', 'post-upload', 'error', "Upload of file #{name} failed with s3 context #{s3.context}")
        success = false
      end
      success
    end

    def update_aptrust_db(uploaded)
      begin
        record = AptrustUpload.find_by!(noid: monograph_presenter.id)
      rescue ActiveRecord::RecordNotFound => e
        apt_log(monograph_presenter.id.to_s, 'exporter - update_aptrust_db', 'post-upload', 'error', "In exporter with monograph #{monograph_presenter.id}, update_aptrust_db find_record error is #{e}")
        return
      end

      if uploaded
        bag_status = BAG_STATUSES['bagged']
        upload_status = S3_STATUSES['uploaded']
        bagged_date = upload_date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      else
        bag_status = BAG_STATUSES['not_bagged']
        upload_status = S3_STATUSES['upload_failed']
        bagged_date = record.date_uploaded
        upload_date = record.date_uploaded
      end

      begin
        record.update!(
          bag_status: bag_status,
          s3_status: upload_status,
          apt_status: APT_STATUSES['not_checked'],
          date_bagged: bagged_date,
          date_uploaded: upload_date,
          date_confirmed: nil
        )
      rescue ActiveRecord::RecordInvalid => e
        apt_log(monograph_presenter.id.to_s, 'exporter - update_aptrust_db', 'post-upload', 'error', "In exporter with monograph #{monograph_presenter.id}, update_aptrust_db record update error is #{e}")
      end
    end

    def apt_log(noid, where, stage, status, action)
      AptrustLog.create(noid: noid,
                        where: where,
                        stage: stage,
                        status: status,
                        action: action)
    rescue AptrustUpload::RecordInvalid => e
      puts "DB error #{e} when trying to log to AptrustLog with noid: #{noid} where: #{where} stage: #{stage} status: #{status} action: #{action}"
    end

    private

      def monograph_presenter
        @monograph_presenter ||= Sighrax.hyrax_presenter(monograph)
      end

      def all_metadata
        return @all_metadata if @all_metadata.present?

        @all_metadata = if @columns == :monograph
                          (ADMIN_METADATA_FIELDS + METADATA_FIELDS).select { |f| %i[universal monograph].include? f[:object] }
                        else
                          ADMIN_METADATA_FIELDS + METADATA_FIELDS + FILE_SET_FLAG_FIELDS
                        end
      end

      def metadata_row(item, parent_rep = nil)
        row = []
        return row if item.instance_of?(Sighrax::NullEntity)
        object_type = item.has_model == 'Monograph' ? :monograph : :file_set
        all_metadata.each do |field|
          row << metadata_field_value(item, object_type, field, parent_rep)
        end
        row
      end

      def metadata_field_value(item, object_type, field, parent_rep) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # this gets around the FileSet's label not matching the original_file's name post-versioning
        # safe navigation is important as we have fileless FileSets in production and specs
        return file_name(item) if object_type == :file_set && field[:field_name] == 'File Name'
        return representative_kind_or_cover(item, parent_rep) if object_type == :file_set && field[:field_name] == 'Representative Kind'
        return item_url(item, object_type) if field[:object] == :universal && field[:field_name] == 'Link'
        return file_set_embed_code(item) if object_type == :file_set && field[:field_name] == 'Embed Code'
        return field_value(item, field[:metadata_name], field[:multivalued]) if field[:object] == :universal || field[:object] == object_type
        return MONO_FILENAME_FLAG if object_type == :monograph && (['label', 'section_title'].include? field[:metadata_name])
      end

      def file_name(item)
        # ensure no entry appears in the "File Name" column for "fileless FileSets"
        fileless_fileset(item) ? nil : CGI.unescape(item&.original_name&.first)
      end

      def fileless_fileset(file_set)
        file_set.external_resource_url.present? || file_set.file_size.blank? || file_set.file_size.zero?
      end

      def representative_kind_or_cover(item, parent_rep)
        # I think we can ignore thumbnail_id, should always be the same as representative_id for us
        return 'cover' if parent_rep == item.id

        FeaturedRepresentative.where(file_set_id: item.id, monograph_id: monograph.noid).first&.kind
      end

      def item_url(item, item_type)
        link = if item_type == :monograph
                 Rails.application.routes.url_helpers.hyrax_monograph_url(item.id)
               else
                 Rails.application.routes.url_helpers.hyrax_file_set_url(item.id)
               end
        '=HYPERLINK("' + link + '")'
      end

      def file_set_embed_code(file_set)
        file_set.embed_code
      end

      def field_value(item, metadata_name, multivalued) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return if item.public_send(metadata_name).blank?
        value = Array.wrap(item.public_send(metadata_name))

        if multivalued == :yes_split
          # Any intended order within a multi-valued field is lost after having been stored in an...
          # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically on export.
          # Items whose order must be preserved should never be stored in an `ActiveTriples::Relation`.
          value.sort.join('; ')
        elsif multivalued == :yes
          # this is a multi-valued field but we're only using it to hold one value
          # Because of TitlePresenter, the title value returned by the presenter will be HTML
          # I don't want to convert HTML to Markdown here, so taking title from the Solr doc
          case metadata_name
          when 'title'
            return item.solr_document['title_tesim'].first
          else
            return value.first
          end
        elsif multivalued == :yes_multiline
          # note1: this is a multi-valued field but we're only using the first one to hold a string containing...
          #        ordered, newline-separated values. Need such to be semi-colon-separated in a cell once again
          # note2: now making `item` a presenter for speed. Given that there was no clean value on the Solr doc...
          #        these were specifically indexed for the exporter
          case metadata_name
          when 'creator'
            return item.solr_document['importable_creator_ss']
          when 'contributor'
            return item.solr_document['importable_contributor_ss']
          else
            # shouldn't happen as creator/contributor are the only :yes_multiline fields
            return value.first
          end
        else
          # https://tools.lib.umich.edu/jira/browse/HELIO-2321
          metadata_name == 'doi' ? 'https://doi.org/' + value.first : value.first
        end
      end
  end
end
