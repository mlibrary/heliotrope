module Import
  class Importer
    attr_reader :root_dir, :press_subdomain, :visibility

    def initialize(root_dir, press_subdomain, visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
      @root_dir = root_dir
      @press_subdomain = press_subdomain
      @visibility = visibility
    end

    def run
      validate_press
      csv_files.each do |file|
        attrs = CSVParser.new(file).attributes
        file_attrs = attrs.delete('files_metadata')
        attrs = transform_attributes(attrs)

        builder = MonographBuilder.new(user, attrs)
        builder.run
        update_fileset_metadata(builder.curation_concern, file_attrs)
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

      def transform_attributes(attrs)
        attributes = attrs.merge('press' => press_subdomain, 'visibility' => visibility)
        attributes['files'] = attrs['files'].map do |file|
          File.new(find_file(file))
        end
        attributes
      end

      # TODO: If the file is missing, raise an error?
      # TODO: Raise an error if find more than 1 file
      def find_file(file_name)
        match = Dir.glob("#{root_dir}/**/#{file_name}")
        match.first
      end

      def user
        @user ||= User.new(user_key: 'system')
      end

      # The 'attrs' parameter is an array of hashes.
      # Each hash in the array is a set of attributes for one
      # FileSet.  The array is in the correct order to match
      # the order of the filesets in the ordered_members list.
      def update_fileset_metadata(monograph, attrs)
        monograph.ordered_members.to_a.each_with_index do |member, i|
          builder = FileSetBuilder.new(member, user, attrs[i])
          builder.run
        end
      end
  end
end
