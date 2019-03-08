# frozen_string_literal: true

require 'csv'
require 'bagit'
require 'aws-sdk-s3'

BAG_STATUSES = { 'not_bagged' => 0, 'bagged' => 1, 'bagging_failed' => 3 }.freeze
S3_STATUSES = { 'not_uploaded' => 0, 'uploaded' => 1, 'upload_failed' => 3 }.freeze
APT_STATUSES = { 'not_checked' => 0, 'confirmed' => 1, 'pending' => 3, 'failed' => 4 }.freeze

module Export
  class Exporter
    attr_reader :all_metadata, :monograph, :columns, :aptrust

    def initialize(monograph_id, columns = :all)
      @monograph = Monograph.find(monograph_id) if monograph_id.present?
      @columns = columns
      #  Use aws credentials for atrust
      filename = Rails.root.join('config', 'aptrust.yml')
      yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
      @aptrust = yaml || nil
    end

    def export_bag # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      ## create bag directory with valid, noid-based aptrust name
      bag_name = "umich.fulcrum-#{@monograph.press}-#{@monograph.id}"
      bag_pathname = "#{Settings.aptrust_bags_path}/#{bag_name}"

      # DESKTOP TESTING ONLY
      # bag_pathname = "./../heliotrope-assets/aptrust-bags/#{bag_name}"

      # On the first run these shouldn't be needed but...
      # clean up bag and tar files
      if File.exist?(bag_pathname)
        puts "-- removing existing bag for #{bag_name}"
        FileUtils.rm_rf(bag_pathname)
      end

      if File.exist?("#{bag_pathname}.tar")
        puts "-- removing tar file for #{bag_name}"
        FileUtils.rm_rf("#{bag_pathname}.tar")
      end

      puts "-- Archiving #{bag_name}"
      bag = BagIt::Bag.new bag_pathname

      # add bagit-info.txt file
      timestamp = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      bag.write_bag_info(
        'Source-Organization' => 'University of Michigan',
        'Bag-Count' => '1',
        'Bagging-Date' => timestamp
      )

      # add aptrust-info.txt file
      # this is stuff that shows up in the APTrust web interface
      # title, access, and descriptoin are required; Storage-Option defaults to Standard if not present
      File.open(File.join(bag.bag_dir, 'aptrust-info.txt'), "w") do |io|
        ti = (@monograph.title.blank? || @monograph.title.empty?) ? '' : @monograph.title.first
        io.puts "Title: #{ti}"

        io.puts "Access: Institution"
        io.puts "Storage-Option: Standard"

        des = (@monograph.description.blank? || @monograph.description.empty?) ? 'Description not available' : @monograph.description.first
        io.puts "Description: #{des}"

        pr = (@monograph.press.blank? || @monograph.press.empty?) ? '' : @monograph.press
        io.puts "Press: #{pr}"

        # I'm assuming Fulcrum will have a different type of music object at some point
        io.puts "Type: monograph"
      end

      # put fulcrum files into data directory
      extract("#{bag.bag_dir}/data/")

      # create manifests
      bag.manifest!

      # tar and remove bag directory
      # but first change to the aptrust-bags directory
      restore_dir = Dir.pwd
      Dir.chdir(Settings.aptrust_bags_path)

      Minitar.pack(bag_name, File.open("#{bag_name}.tar", 'wb'))
      FileUtils.rm_rf(bag_name)

      # Upload the bag to the s3 bucket (umich A&E test bucket for now)
      uploaded = send_to_s3("#{bag_name}.tar")

      # now restore the previous directory
      Dir.chdir(restore_dir)

      # Update AptrustUploads database if bag is processed
      if uploaded
        update_aptrust_db
      else
        puts "Upload failed for #{bag_pathname}.tar"
      end
    end

    def export
      return String.new if @monograph.blank?
      rows = []
      @monograph.ordered_members.to_a.each do |member|
        rows << metadata_row(member, :file_set)
      end
      rows << metadata_row(@monograph, :monograph)
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
        rows.each { |row| csv << row if row.present? }
      end
      buffer
    end

    def extract(use_dir = nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return if @monograph.blank?
      if use_dir
        path = "#{use_dir}/"
      else
        base = File.join(".", "extract")
        FileUtils.mkdir(base) unless Dir.exist?(base)
        press = File.join(base, @monograph.press.to_s)
        FileUtils.mkdir(press) unless Dir.exist?(press)
        path = File.join(press, @monograph.id.to_s)
        if Dir.exist?(path)
          puts "Overwrite #{path} directory? (Y/n):"
          return unless /y/i.match?(STDIN.getch)
          FileUtils.rm_rf(path)
        end
        FileUtils.mkdir(path)
      end
      manifest = File.new(File.join(path, @monograph.id.to_s + ".csv"), "w")
      manifest << export
      manifest.close
      @monograph.ordered_members.to_a.each do |member|
        next unless member.original_file
        filename = CGI.unescape(member.original_file.file_name.first)
        file = File.new(File.join(path, filename), "wb")
        file.write(member.original_file.content.force_encoding("utf-8"))
        file.close
      end
    end

    def monograph_row
      metadata_row(@monograph, :monograph)
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
      if fulcrum_bucket.object(name).exists?
        puts "#{name} already exists in the bucket: #{bucket_name} overwriting bag!"
      end

      begin
        # Create the object to upload and upload it
        obj = s3.bucket(bucket_name).object(name)
        obj.upload_file(file)
        success = true
      rescue Aws::S3::Errors::ServiceError
        puts "Upload of file {name} fails with s3 context #{s3.context}"
        success = false
      end
      success
    end

    def update_aptrust_db
      begin
        record = AptrustUpload.find_by!(noid: @monograph.id)
      rescue ActiveRecord::RecordNotFound => e
        puts "In exporter with monograph #{@monograph.id}, find_record error is #{e} "
        return
      end

      begin
        current_date = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
        record.update!(
          bag_status: BAG_STATUSES['bagged'],
          s3_status: S3_STATUSES['uploaded'],
          apt_status: APT_STATUSES['not_checked'],
          date_fileset_modified: nil,
          date_bagged: current_date,
          date_uploaded: current_date,
          date_confirmed: nil
        )
      rescue ActiveRecord::RecordInvalid => e
        puts "In exporter with monograph #{@monograph.id}, record.update error is #{e}"
      end
    end

    private

      def all_metadata
        return @all_metadata if @all_metadata.present?
        @all_metadata = if @columns == :monograph
                          (ADMIN_METADATA_FIELDS + METADATA_FIELDS).select { |f| %i[universal monograph].include? f[:object] }
                        else
                          ADMIN_METADATA_FIELDS + METADATA_FIELDS + FILE_SET_FLAG_FIELDS
                        end
      end

      def metadata_row(item, object_type)
        row = []
        all_metadata.each do |field|
          row << metadata_field_value(item, object_type, field)
        end
        row
      end

      def metadata_field_value(item, object_type, field) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # this gets around the FileSet's label not matching the original_file's name post-versioning
        # safe navigation is important as we have fileless FileSets in production and specs
        return item&.original_file&.file_name&.first if object_type == :file_set && field[:field_name] == 'File Name'
        return representative_kind_or_cover(item) if object_type == :file_set && field[:field_name] == 'Representative Kind'
        return item_url(item, object_type) if field[:object] == :universal && field[:field_name] == 'Link'
        return file_set_embed_code(item) if object_type == :file_set && field[:field_name] == 'Embed Code'
        return field_value(item, field[:metadata_name], field[:multivalued]) if field[:object] == :universal || field[:object] == object_type
        return MONO_FILENAME_FLAG if object_type == :monograph && (['label', 'section_title'].include? field[:metadata_name])
      end

      def representative_kind_or_cover(item)
        # I think we can ignore thumbnail_id, should always be the same as representative_id for us
        return 'cover' if item.parent.representative_id == item.id
        FeaturedRepresentative.where(file_set_id: item.id, monograph_id: @monograph.id).first&.kind
      end

      def item_url(item, item_type)
        link = if item_type == :monograph
                 Rails.application.routes.url_helpers.hyrax_monograph_url(item)
               else
                 Rails.application.routes.url_helpers.hyrax_file_set_url(item)
               end
        '=HYPERLINK("' + link + '")'
      end

      def file_set_embed_code(file_set)
        Hyrax::FileSetPresenter.new(SolrDocument.new(file_set.to_solr), nil).embed_code
      end

      def field_value(item, metadata_name, multivalued)
        return if item.public_send(metadata_name).blank?
        if multivalued == :yes_split
          # Any intended order within a multi-valued field is lost after having been stored in an...
          # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically on export.
          # Items whose order must be preserved should never be stored in an `ActiveTriples::Relation`.
          item.public_send(metadata_name).sort.join('; ')
        elsif multivalued == :yes
          # this is a multi-valued field but we're only using it to hold one value
          item.public_send(metadata_name).first
        elsif multivalued == :yes_multiline
          # this is a multi-valued field but we're only using the first one to hold a string containing...
          # ordered, newline-separated values. Need such to be semi-colon-separeated in a cell once again
          item.public_send(metadata_name).first.split(/\r?\n/).reject(&:blank?).join('; ')
        else
          # https://tools.lib.umich.edu/jira/browse/HELIO-2321
          metadata_name == 'doi' ? 'https://doi.org/' + item.public_send(metadata_name) : item.public_send(metadata_name)
        end
      end
  end
end
