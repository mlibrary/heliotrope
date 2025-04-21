# frozen_string_literal: true

require 'csv'

module Import
  class Importer
    include ::Hyrax::Noid

    attr_reader :root_dir, :user_email, :press_subdomain, :monograph_id, :monograph_title,
                :visibility, :reimporting, :reimport_mono, :reuse_noids, :quiet

    def initialize(root_dir: '', user_email: '', monograph_id: '', press: '',
                   visibility: '', monograph_title: '', quiet: '', reuse_noids: false)

      @root_dir = root_dir
      @user_email = user_email
      @reimporting = false
      @reimport_mono = Monograph.where(id: monograph_id).first
      @quiet = quiet
      @reuse_noids = reuse_noids

      # visibility is set according to this hierarchy:
      #  1) if present, the importer visibility parameter (likely from command line `-v` option) trumps everything for all objects in the current import
      #  2) a `Published?` value present on an object's CSV row will be used for that object
      #  3) otherwise, for FileSets with no `Published?` value on their CSV row, the Monograph's visibility will be used
      #  4) when no visibility is set at all, it defaults to draft/restricted

      @explicit_visibility = visibility.present?
      @visibility = @explicit_visibility ? visibility : Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

      if monograph_id.present?
        raise "No monograph found with id '#{monograph_id}'" if @reimport_mono.blank?
        @reimporting = true
      else
        @press_subdomain = press
        @monograph_title = monograph_title
      end
    end

    # TODO: remove this if/when import() is rewritten to use CSVParser
    def metadata_field(key)
      (METADATA_FIELDS + FILE_SET_FLAG_FIELDS).each do |field|
        return field if key == field[:field_name]
      end
      nil
    end

    # TODO: remove this if/when import() is rewritten to use CSVParser
    def metadata_field_value(field, value)
      return (value == 'true' ? 'open' : 'restricted') if field[:metadata_name] == 'visibility'
      return value if field[:multivalued] == :no
      return [value] if field[:multivalued] == :yes
      return value.split(';') if value.present?
      []
    end

    # TODO: remove this if/when import() is rewritten to use CSVParser
    def metadata_monograph_field?(key)
      field = metadata_field(key)
      return field[:object] != :file_set if field.present?
      false
    end

    # TODO: remove this if/when import() is rewritten to use CSVParser
    def metadata_file_set_field?(key)
      field = metadata_field(key)
      return field[:object] != :monograph if field.present?
      false
    end

    def set_representative_or_cover(monograph, file_set, representative_kind)
      if representative_kind == 'cover'
        monograph.representative_id = file_set.id
        monograph.thumbnail_id = file_set.id
        monograph.save!
        return
      end

      current_representative = FeaturedRepresentative.where(work_id: monograph.id, file_set_id: file_set.id).first
      if current_representative.present?
        if current_representative.kind == representative_kind
          return
        else
          current_representative.destroy!
        end
      end
      FeaturedRepresentative.create!(work_id: monograph.id, file_set_id: file_set.id, kind: representative_kind)
      # always update a FileSet's Solr doc after making it a FeaturedRepresentative or cover
      file_set.update_index
    end

    # TODO: see if this method, which makes up part of the currently-unused/experimental UI "manifest"...
    # download/edit/upload workflow, can be rewritten to use CSVParser. Right now it deviates and does not map...
    # all the fields as intended.
    def import(manifest) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return false if @reimport_mono.blank?
      monograph = @reimport_mono
      rows = CSV.parse(manifest, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
      # The template CSV file contains an extra row after the
      # headers that has explanatory text about how to fill in
      # the table.  We want to throw away that text.
      rows.delete(0)
      rows.each do |row|
        noid = row.field('NOID')
        row.each do |key, value|
          field = metadata_field(key)
          next if field.blank? || value.blank?
          if noid == monograph.id
            if metadata_monograph_field?(key)
              monograph.send("#{field[:metadata_name]}=", metadata_field_value(field, value))
              monograph.save
            end
          elsif metadata_file_set_field?(key)
            file_set = FileSet.find(noid)
            if key == 'Representative Kind'
              set_representative_or_cover(monograph, file_set, value.strip.downcase)
            else
              file_set.send("#{field[:metadata_name]}=", metadata_field_value(field, value))
              file_set.save
            end
          end
        end
      end
      true
    end

    def run(test = false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      interaction = !Rails.env.test? && !@quiet

      validate_user
      validate_press unless reimporting

      # Not ideal maybe but reusing `root_dir` for optional import of tarball is what's happening!
      # Doing the switcheroo here means no alterations needed to the rest of the importer or script/import,...
      # and won't/shouldn't affect usages such as those described here, either:
      # https://mlit.atlassian.net/wiki/spaces/FUL/pages/9320892681/Batch+extract+and+import+of+a+Press+s+Monographs

      if File.exist?(root_dir) && File.extname(root_dir) == '.tar'
        monograph_id = File.basename(root_dir, '.tar')
        tmp_dir_path = File.join(Settings.scratch_space_path, "importing-tarball-#{monograph_id}")
        FileUtils.mkdir_p(tmp_dir_path) if !Dir.exist?(tmp_dir_path)
        Minitar.unpack(root_dir, tmp_dir_path.to_s)
        # our backups are tars of NOID-named directories
        @root_dir = File.join(tmp_dir_path, monograph_id)
      else
        raise "Directory not found: #{root_dir}" unless Dir.exist?(root_dir)
      end

      attrs = CSVParser.new(csv_file, @reuse_noids).attributes

      unless @reimporting # if reimporting then the monograph has a title already
        # tombstoned HEB items have a Monograph title of `[title removed]`. We don't want to import these.
        if attrs['title'].blank? # might as well bow out if the monograph title is blank for some reason too.
          puts "Monograph title cannot be blank. Not importing this Monograph."
          exit # rubocop:disable Rails/Exit
        elsif attrs['title'].first&.strip == '[title removed]'
          puts "HEB tombstoned EPUB detected. Not importing this Monograph."
          exit # rubocop:disable Rails/Exit
        end
      end

      # We've removed the Hyrax behavior where it sets the representative/thumbnail to the first file of any kind...
      # (not just image files) that gets attached to the new Work. However we want backwards-compatibility with our...
      # old imports, so we'll look for an image to assign even without the 'Representative Kind' field set to 'cover'.
      maybe_set_cover(attrs) unless reimporting

      optional_early_exit(interaction, attrs.delete('row_errors'), test)

      # if there is a command-line monograph title then use it
      attrs['title'] = Array(monograph_title) if monograph_title.present?

      # Find file's absolute path and verify it exist?
      absolute_filenames = attrs.delete('files').map do |filename|
        if filename.present? # "External Resources" are FileSets without a file
          find_file(filename) # Raise on error!
        end
      end

      # Wrap files in UploadedFile wrappers using nil for external resources
      uploaded_files = absolute_filenames.map do |filename|
        if filename.present? # "External Resources" are FileSets without a file
          Hyrax::UploadedFile.create(file: File.new(filename), user: user)
        end
      end

      attrs['import_uploaded_files_ids'] = uploaded_files.map { |f| f&.id }
      attrs['import_uploaded_files_attributes'] = attrs.delete('files_metadata')

      # Always use a user-provided visibility, even for additional/"reimported" FileSets. This usually comes from...
      # the command-line `-v` option
      if @explicit_visibility
        attrs['import_uploaded_files_attributes'].each { |fattr| fattr['visibility'] = @visibility }
      end

      if reimporting
        Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(@reimport_mono, Ability.new(user), attrs))
      else
        attrs['press'] = press_subdomain
        # Monograph visibility, explicit (command-line) value takes precedence, then CSV value, then default (draft).
        attrs['visibility'] = if @explicit_visibility
                                @visibility
                              elsif attrs['visibility'].present?
                                attrs['visibility']
                              else
                                Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
                              end

        Hyrax::CurationConcern.actor.create(Hyrax::Actors::Environment.new(Monograph.new, Ability.new(user), attrs))
      end

      # the temporary directory that may have been created if the importer was run against a tar archive
      FileUtils.remove_entry tmp_dir_path if tmp_dir_path.present?
    end

    private

      def validate_user
        return if user_email.blank?
        raise "No user found with email '#{user_email}'. You must enter the email address of an actual user." if user.blank?
      end

      def validate_press
        unless Press.exists?(subdomain: press_subdomain)
          raise "No press found with subdomain: '#{press_subdomain}'"
        end
      end

      def csv_file
        return @csv_file if @csv_file.present?

        csv_files = Dir.glob(File.join(root_dir, '*.csv'))
        csv_files = Dir.glob(File.join(root_dir, 'manifest.csv')) if csv_files.count > 1
        if csv_files.count == 1
          @csv_file = csv_files.first
        else
          raise "Directory #{root_dir} must contain 1 manifest CSV file of any name.\n"\
                "If multiple CSV files are present the manifest file must be named `manifest.csv`\n"
        end
      end

      def find_file(file_name)
        match = Dir.glob(File.join(root_dir, '**', file_name))
        if match.empty?
          raise "'File #{file_name}' not found anywhere under '#{root_dir}'"
        elsif match.count > 1
          raise "More than one file found with name: '#{file_name}'"
        elsif File.zero?(match.first)
          raise "Zero-size file found: '#{file_name}'"
        end
        match.first
      end

      def user
        @user ||= (user_email.present? ? User.find_by(email: user_email) : User.batch_user)
      end

      def optional_early_exit(interaction, errors, test)
        if interaction && errors.present?
          errors.each do |row_num, error|
            puts '-' * 100 + "\nRow #{row_num}" + error + "\n"
          end
          puts '-' * 100 + "\n"
          puts "\n\nSome rows/fields have been flagged for your approval. Please review the messages above before proceeding.\n"
          exit if test == true # rubocop:disable Rails/Exit
          puts "Do you wish to continue (y/n)?"
          continue = gets
          exit unless continue.downcase.first == 'y' # rubocop:disable Rails/Exit
        end
        # command-line option to exit
        exit if test == true # rubocop:disable Rails/Exit
      end

      def maybe_set_cover(attrs)
        if attrs['files_metadata'].none? { |metadata| metadata['representative_kind'] == 'cover' }
          # flag first image found as the cover to maintain expected behavior for FMSL CSV imports
          attrs['files'].each_with_index do |file, i|
            next if file.blank? # external resources
            if ['.bmp', '.jpg', '.jpeg', '.png', '.gif', '.tif', '.tiff'].include?(File.extname(file).downcase)
              attrs['files_metadata'][i]['representative_kind'] = 'cover'
              break
            end
          end
        end
      end
  end
end
