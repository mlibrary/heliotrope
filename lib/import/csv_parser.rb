module Import
  class CSVParser
    attr_reader :file

    def initialize(input_file)
      @file = input_file
    end

    def attributes
      attrs = {}

      # a CSV can only have one monograph (probably for in-house use only)...
      attrs['monograph'] = {}
      attrs['monograph']['files'] = []
      attrs['monograph']['files_metadata'] = []
      # ... but can have many sections
      attrs['sections'] = {}

      puts "Parsing file: #{file}"
      rows = CSV.read(file, headers: true)

      # The template CSV file contains an extra row after the
      # headers that has explanatory text about how to fill in
      # the table.  We want to throw away that text.
      rows.delete(0)

      rows.each do |row|
        row.each { |_, value| value.strip! if value }

        #next if required_fields_missing(row)
        if asset_data?(row)
          puts "ASSET"
          data_for_asset(row, attrs)
        else
          puts "MONOGRAPH"
          data_for_monograph(row, attrs['monograph'])
        end
      end

      attrs
    end

    private

      def asset_data?(data)
        data['File Name'] != '://:MONOGRAPH://:' && data['Section'] != '://:MONOGRAPH://:'
      end

      # TODO: With this code, the last row wins.  We need to
      # decide if we expect the file to have more than 1 row
      # of data, and handle additional rows accordingly.
      def data_for_monograph(row, attrs)
        title = Array(row['Title'].split(';')).map(&:strip)
        puts "  Monograph: #{title.first}"

        attrs['title'] = title
        attrs['creator'] = creator(row)
      end

      def data_for_asset(row, attrs)
        # do a section check

        file_attrs = {}
        missing_fields = []
        #validate_data(data, file_attrs)

        metadata_fields.each do |field|
          if row[field['field_name']]
            if row[field['multi_value']] == true
              file_attrs[field['metadata_name']] = Array(row[field['field_name']].split(';')).map(&:strip)
            else
              file_attrs[field['metadata_name']] = Array(row[field['field_name']].strip)
            end
          elsif row[field['required']]
            # add to array of missing stuff
            missing_required_fields.add(row[field['field_name']])
          end
        end

        # creator is speicial as it requires to adding two fields together
        file_attrs['creator'] = creator(row)

        puts "    Asset: (#{row['File Name']}) #{file_attrs['title'].first}"
        attach_asset(row, attrs, file_attrs)
      end

      def attach_asset(row, attrs, file_attrs)
        # blank section will mean 'attach to monograph'
        attach_to_monograph = false
        if !row['Section'].nil? && row['Section'] != '' && row['Section'] != '://:MONOGRAPH://:'
          section_title = row['Section']
        else
          section_title = '://:MONOGRAPH://:'
       end

        # using parallel arrays for files and their metadata
        # for both monographs and sections
        unless section_title == '://:MONOGRAPH://:'
          # create section if new
          unless attrs['sections'][section_title]
            current_section = {}
            current_section['title'] = Array(row['Section'].split(';')).map(&:strip)
            current_section['files'] = []
            current_section['files_metadata'] = []
            attrs['sections'][section_title] = current_section
          end
          attrs['sections'][section_title]['files'] << row['File Name']
          attrs['sections'][section_title]['files_metadata'] << file_attrs
          puts "    ... will attach to Section: #{section_title}"
        else
          # An array of file names with a matching array of
          # metadata for each of those files.
          attrs['monograph']['files'] << row['File Name']
          attrs['monograph']['files_metadata'] << file_attrs
          puts "    ... will attach directly to monograph"
        end

        # TODO: The matching arrays will only work if they
        # both contain exactly the same number of elements.
        # We should either store the file name together with
        # the metadata, or else raise an error if the 2 arrays
        # don't have the same count.
      end

      def creator(row)
        last_name = row['Primary Creator Last Name'] ? row['Primary Creator Last Name'] : ''
        first_name = row['Primary Creator First Name'] ? row['Primary Creator First Name'] : ''
        joining_comma = last_name.blank? || first_name.blank? ? '' : ', '
        full_name = last_name + joining_comma + first_name
        full_name.blank? ? nil : Array(full_name)
      end

      def metadata_fields
        [
          { 'field_name' => 'Title', 'metadata_name' => 'title', 'required' => true, 'multi_value' => false },
          { 'field_name' => 'Caption', 'metadata_name' => 'caption', 'required' => true, 'multi_value' => true },
          { 'field_name' => 'Alternative Text', 'metadata_name' => 'alt_text', 'required' => true, 'multi_value' => true },
          { 'field_name' => 'Resource Type', 'metadata_name' => 'content_type', 'required' => true, 'multi_value' => true },
          { 'field_name' => 'Copyright Holder', 'metadata_name' => 'copyright_holder', 'required' => true, 'multi_value' => true },
          { 'field_name' => 'Externally Hosted Resource', 'metadata_name' => 'external_resource', 'required' => true, 'multi_value' => true },
          { 'field_name' => 'Persistent ID', 'metadata_name' => 'persistent_id', 'required' => true, 'multi_value' => true }
        ]
      end
  end
end
