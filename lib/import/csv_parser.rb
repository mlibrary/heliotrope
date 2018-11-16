# frozen_string_literal: true

require 'csv'

module Import
  class CSVParser
    attr_reader :file

    def initialize(input_file)
      @file = input_file
    end

    def attributes(stream = nil)
      attrs = {}

      # a CSV can only have one monograph (probably for in-house use only)...
      attrs = {}
      attrs['files'] = []
      attrs['files_metadata'] = []
      attrs['row_errors'] = {}

      rows = if stream.present?
               CSV.parse(stream, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
             else
               puts "Parsing file: #{file}"
               CSV.read(file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
             end
      row_data = RowData.new

      # look for unexpected column names which will be ignored. note: 'File Name' is not in METADATA_FIELDS.
      unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - (METADATA_FIELDS.pluck :field_name) - ['File Name']
      attrs['row_errors'][0] = "\n***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped:\n" + unexpecteds.join(', ') unless unexpecteds.count.zero?

      # human-readable row counter (3 accounts for the top two discarded rows)
      row_num = 3

      # The template CSV file contains an extra row after the
      # headers that has explanatory text about how to fill in
      # the table.  We want to throw away that text.
      rows.delete(0)

      rows.each do |row|
        row.each { |_, value| value&.strip! }

        if missing_file_name?(row)
          attrs['row_errors'][row_num] = "\nFile name can only be missing for external resources - row will be skipped"
          row_num += 1
          next
        end

        if asset_data?(row)
          file_attrs = {}
          row_data.data_for_asset(row_num, row, file_attrs, attrs['row_errors'])
          attach_asset(row, attrs, file_attrs)
        else
          row_data.data_for_monograph(row, attrs)
        end
        row_num += 1
      end
      attrs
    end

    private

      def missing_file_name?(row)
        row['File Name'].blank? && row['External Resource URL'].blank?
      end

      def asset_data?(row)
        row['File Name'] != MONO_FILENAME_FLAG && row['Section'] != MONO_FILENAME_FLAG
      end

      def attach_asset(row, attrs, file_attrs)
        attrs['files'] << row['File Name'] || ''
        attrs['files_metadata'] << file_attrs

        # TODO: The matching arrays will only work if they
        # both contain exactly the same number of elements.
        # We should either store the file name together with
        # the metadata, or else raise an error if the 2 arrays
        # don't have the same count.
      end

      def get_section_title(row)
        row['Section'].presence || '://:MONOGRAPH://:'
      end
  end
end
