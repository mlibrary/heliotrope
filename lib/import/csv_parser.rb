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
        if asset_data?(row)
          data_for_asset(row, attrs)
        else
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
      def data_for_monograph(data, attrs)
        title = Array(data['Title'].split(';')).map(&:strip)
        puts "  Monograph: #{title.first}"

        attrs['title'] = title
        attrs['creator_family_name'] = creator_family_name(data)
        attrs['creator_given_name'] = creator_given_name(data)
      end

      def data_for_asset(data, attrs)
        title = Array(data['Title'].split(';')).map(&:strip)
        puts "    Asset: (#{data['File Name']}) #{title.first}"

        file_attrs = {}
        file_attrs['title'] = title
        file_attrs['creator_family_name'] = creator_family_name(data)
        file_attrs['creator_given_name'] = creator_given_name(data)

        # blank section will mean 'attach to monograph'
        # this section_title will also be used as section key, but a curation_concern...
        # can have several titles, so the actual section title is an array (see below)
        section_title = data['Section']

        # using parallel arrays for files and their metadata
        # for both monographs and sections
        if section_title
          section_title = section_title.strip
          # will need to know what section to attach the file to later???
          unless attrs['sections'][section_title]
            current_section = {}
            current_section['title'] = Array(data['Section'].split(';')).map(&:strip)
            current_section['files'] = []
            current_section['files_metadata'] = []
            attrs['sections'][section_title] = current_section
          end
          attrs['sections'][section_title]['files'] << data['File Name']
          attrs['sections'][section_title]['files_metadata'] << file_attrs
          puts "    ... will attach to Section: #{section_title}"
        else
          # An array of file names with a matching array of
          # metadata for each of those files.
          attrs['monograph']['files'] << data['File Name']
          attrs['monograph']['files_metadata'] << file_attrs
          puts "    ... will attach directly to monograph"
        end

        # TODO: The matching arrays will only work if they
        # both contain exactly the same number of elements.
        # We should either store the file name together with
        # the metadata, or else raise an error if the 2 arrays
        # don't have the same count.
      end

      def creator_family_name(data)
        return unless data['Primary Creator Last Name']
        data['Primary Creator Last Name'].strip
      end

      def creator_given_name(data)
        return unless data['Primary Creator First Name']
        data['Primary Creator First Name'].strip
      end
  end
end
