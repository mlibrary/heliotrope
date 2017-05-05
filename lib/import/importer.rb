module Import
  class Importer
    attr_reader :root_dir, :press_subdomain, :monograph_id, :monograph_title, :visibility, :reimporting

    def initialize(root_dir, press_subdomain, visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, monograph_title = '', monograph_id = '')
      @root_dir = root_dir
      @reimporting = false
      @reimport_mono = Monograph.where(id: monograph_id).first

      if monograph_id.present?
        raise "No monograph found with id #{monograph_id}" if @reimport_mono.blank?
        @reimporting = true
      else
        @press_subdomain = press_subdomain
        @visibility = visibility
        @monograph_title = monograph_title
      end
    end

    def run(test = false)
      interaction = !Rails.env.test?
      validate_press unless reimporting
      csv_files.each do |file|
        errors = ''
        attrs = CSVParser.new(file).attributes(errors)

        # if there is a command-line monograph title then use it
        attrs['title'] = Array(monograph_title) if monograph_title.present?

        # create file objects (stop everything here if any are not found, duplicates or of zero size)
        file_objects(attrs)

        optional_early_exit(interaction, errors, test)

        # because the MonographBuilder sets its metadata, files_metadata has to be removed here
        file_attrs = attrs.delete('files_metadata')

        if reimporting
          # TODO: make add_new_filesets return something sensible?
          raise "There may have been a problem attaching the new files" unless add_new_filesets(@reimport_mono, attrs, file_attrs)
        else
          attrs.merge!('press' => press_subdomain, 'visibility' => visibility)
          monograph_builder = MonographBuilder.new(user, attrs)
          monograph_builder.run
          monograph = monograph_builder.curation_concern
          update_fileset_metadata(monograph, file_attrs)
          representative_image(monograph)
        end
      end
    end

    private

      def validate_press
        unless Press.exists?(subdomain: press_subdomain)
          raise "No press found with subdomain: '#{press_subdomain}'"
        end
      end

      def csv_files
        fail "Directory not found: #{root_dir}" unless File.exist?(root_dir)
        @csv_files ||= Dir.glob(File.join(root_dir, '*.csv'))
      end

      def file_objects(attrs)
        # assigning empty files a generic link icon here, should be external resources
        attrs['files'] = attrs['files'].map do |file|
          # setting external resources to '' here (not nil) gets the FileSet created using the existing...
          # CC actor stack, as long as we also bow out just before ingest in FileSetActor's create_content
          file.blank? ? '' : File.new(find_file(file))
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
        @user ||= DummyUser.new(id: 0, user_key: 'system')
      end

      # The 'attrs' parameter is an array of hashes.
      # Each hash in the array is a set of attributes for one
      # FileSet.  The array is in the correct order to match
      # the order of the filesets in the ordered_members list.
      def update_fileset_metadata(work, attrs)
        work.ordered_members.to_a.each_with_index do |member, i|
          builder = FileSetBuilder.new(member, user, attrs[i])
          builder.run
        end
      end

      def add_new_filesets(monograph, attrs, file_attrs)
        [attrs['files'], file_attrs].transpose.each do |file, metadata|
          file_set = FileSet.new
          file_set_actor = CurationConcerns::Actors::FileSetActor.new(file_set, user)
          file_set_actor.create_metadata(monograph, metadata)
          file_set_actor.create_content(file)
          file_set_actor.update_metadata(metadata)
        end
      end

      def optional_early_exit(interaction, errors, test)
        if interaction && errors.present?
          puts "\n" + errors + "\n" + "-" * 100 + "\n"
          puts "\n\nSome rows/fields have been flagged for your approval. Please review the messages above before proceeding.\n"
          exit if test == true
          puts "Do you wish to continue (y/n)?"
          continue = gets
          exit unless continue.downcase.first == 'y'
        end
        # command-line option to exit
        exit if test == true
      end

      def representative_image(monograph)
        cover_id = monograph.ordered_members.to_a.first.id
        puts "Saving #{cover_id} as the cover"
        monograph.representative_id = cover_id
        monograph.thumbnail_id = cover_id
        monograph.save!

        # I think that because the cover essentially has no metadata (just the file name),
        # it's not included in file_attrs (it is but it's just {}) and so
        # never gets it's metadata updated as the other file_sets do.
        # For some reason this seems to cause the technical metadata from Characterization
        # to not be in solr. This seems to fix that. TODO: investigate this more.
        FileSet.find(cover_id).update_index
      end
  end
end
