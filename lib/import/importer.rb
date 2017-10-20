module Import
  class Importer
    include ::Hyrax::Noid

    attr_reader :root_dir, :user_email, :press_subdomain, :monograph_id, :monograph_title,
                :visibility, :reimporting, :reimport_mono

    def initialize(root_dir: '', user_email: '', monograph_id: '', press: '',
                   visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
                   monograph_title: '')

      @root_dir = root_dir
      @user_email = user_email
      @reimporting = false
      @reimport_mono = Monograph.where(id: monograph_id).first

      if monograph_id.present?
        raise "No monograph found with id '#{monograph_id}'" if @reimport_mono.blank?
        @reimporting = true
      else
        @press_subdomain = press
        @visibility = visibility
        @monograph_title = monograph_title
      end
    end

    def run(test = false)
      interaction = !Rails.env.test?
      validate_user
      validate_press unless reimporting
      csv_files.each do |file|
        attrs = CSVParser.new(file).attributes

        # if there is a command-line monograph title then use it
        attrs['title'] = Array(monograph_title) if monograph_title.present?

        # create file objects (stop everything here if any are not found, duplicates or of zero size)
        file_objects(attrs)

        optional_early_exit(interaction, attrs.delete('row_errors'), test)

        # Because the MonographBuilder sets its metadata, files_metadata has to be removed here
        file_attrs = attrs.delete('files_metadata')
        # The old "files" array cause errors in hyrax2, we need "uploaded_files" which was
        # created above in file_objects(attrs)
        attrs.delete('files')

        if reimporting
          # TODO: make add_new_filesets return something sensible?
          raise "There may have been a problem attaching the new files" unless add_new_filesets(@reimport_mono, attrs, file_attrs)
        else
          attrs.merge!('press' => press_subdomain, 'visibility' => visibility)
          monograph_builder = MonographBuilder.new(user, attrs)
          monograph_builder.run
          monograph = Monograph.find(monograph_builder.curation_concern.id)
          puts "Ingesting files. This could take some time, could be over an hour for 300+ files."
          until monograph.ordered_members.to_a.length == attrs["uploaded_files"].length
            # This is obviously terrible, but we need to wait for all the files to be
            # ingested via the resque jobs before we can update the file_sets with their metadata
            # TODO: Investigate other ways to do this.
            monograph = monograph.reload
            sleep 1
            print "."
          end
          puts "\nUpdating FileSet Metadata"
          update_fileset_metadata(monograph, file_attrs)
        end
      end
    end

    private

      def validate_user
        raise "No user found with email '#{user_email}'. You must enter the email address of an actual user." if user.blank?
      end

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
        uploaded_files = attrs['files'].map do |file|
          if file.present?
            Hyrax::UploadedFile.create(file: File.new(find_file(file)), user: user)
          else
            # "External Resources" are FileSets without a file
            Hyrax::UploadedFile.create(file: File.new("/dev/null"), user: user) # Is File.new("/dev/null") really good here? Leaving it file: "" causes an error...
          end
        end

        attrs['uploaded_files'] = uploaded_files.map(&:id)
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
        @user ||= User.find_by(email: user_email)
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
        [attrs['uploaded_files'], file_attrs].transpose.each do |file, metadata|
          file_set = FileSet.new
          file_set_actor = Hyrax::Actors::FileSetActor.new(file_set, user)
          file_set_actor.create_metadata(metadata)
          file_set_actor.create_content(Hyrax::UploadedFile.find(file))
          file_set_actor.update_metadata(metadata)
          file_set_actor.attach_to_work(monograph, metadata)
        end
      end

      def optional_early_exit(interaction, errors, test)
        if interaction && errors.present?
          errors.each do |row_num, error|
            puts '-' * 100 + "\nRow #{row_num}" + error + "\n"
          end
          puts '-' * 100 + "\n"
          puts "\n\nSome rows/fields have been flagged for your approval. Please review the messages above before proceeding.\n"
          exit if test == true
          puts "Do you wish to continue (y/n)?"
          continue = gets
          exit unless continue.downcase.first == 'y'
        end
        # command-line option to exit
        exit if test == true
      end
  end
end
