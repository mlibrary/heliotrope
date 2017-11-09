# frozen_string_literal: true

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

        optional_early_exit(interaction, attrs.delete('row_errors'), test)

        # if there is a command-line monograph title then use it
        attrs['title'] = Array(monograph_title) if monograph_title.present?

        # Wrap files in UploadedFile wrappers using /dev/null for external resources
        uploaded_files = attrs.delete('files').map do |filename|
          if filename.present?
            Hyrax::UploadedFile.create(file: File.new(find_file(filename)), user: user)
          else
            # "External Resources" are FileSets without a file
            Hyrax::UploadedFile.create(file: File.new("/dev/null"), user: user) # TODO: Is File.new("/dev/null") really good here?
          end
        end
        attrs['import_uploaded_files_ids'] = uploaded_files.map(&:id)
        attrs['import_uploaded_files_attributes'] = attrs.delete('files_metadata')

        if reimporting
          attrs.merge!('visibility' => reimport_mono.visibility)
          Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(@reimport_mono, Ability.new(user), attrs))
        else
          attrs.merge!('press' => press_subdomain, 'visibility' => visibility)
          Hyrax::CurationConcern.actor.create(Hyrax::Actors::Environment.new(Monograph.new, Ability.new(user), attrs))
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
