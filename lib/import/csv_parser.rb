require 'csv'

module Import
  class CSVParser
    attr_reader :file

    def initialize(input_file)
      @file = input_file
    end

    def attributes(errors_out = '')
      attrs = {}

      # a CSV can only have one monograph (probably for in-house use only)...
      attrs['monograph'] = {}
      attrs['monograph']['files'] = []
      attrs['monograph']['files_metadata'] = []

      puts "Parsing file: #{file}"
      rows = CSV.read(file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
      row_data = RowData.new

      # human-readable row counter (3 accounts for the top two discarded rows)
      row_num = 3

      # The template CSV file contains an extra row after the
      # headers that has explanatory text about how to fill in
      # the table.  We want to throw away that text.
      rows.delete(0)

      skipped_array = []
      errors_array = []

      rows.each do |row|
        row.each { |_, value| value.strip! if value }

        if missing_file_name?(row)
          skipped_array << "Row #{row_num}: File name can only be missing for external resources - row will be skipped\n"
          row_num += 1
          next
        end

        if asset_data?(row)
          file_attrs = {}
          errors_array << row_data.data_for_asset(row_num, row, file_attrs)
          attach_asset(row, attrs, file_attrs)
        else
          row_data.data_for_monograph(row, attrs['monograph'])
        end
        row_num += 1
      end

      errors_out.replace skipped_array.join + "\n\n" + errors_array.join
      attrs
    end

    private

      def missing_file_name?(row)
        row['File Name'].blank? && row['Externally Hosted Resource'] != 'yes'
      end

      def asset_data?(row)
        row['File Name'] != MONO_FILENAME_FLAG && row['Section'] != MONO_FILENAME_FLAG
      end

      def attach_asset(row, attrs, file_attrs)
        attrs['monograph']['files'] << row['File Name'] || ''
        attrs['monograph']['files_metadata'] << file_attrs

        # TODO: The matching arrays will only work if they
        # both contain exactly the same number of elements.
        # We should either store the file name together with
        # the metadata, or else raise an error if the 2 arrays
        # don't have the same count.
      end

      def get_section_title(row)
        row['Section'].blank? ? '://:MONOGRAPH://:' : row['Section']
      end
  end
end
