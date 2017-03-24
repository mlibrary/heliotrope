require 'date'
require 'redcarpet'
require 'redcarpet/render_strip'

module Import
  class RowData
    attr_reader :row, :attrs

    def data_for_monograph(row, attrs)
      fields = METADATA_FIELDS.select { |f| [:universal, :monograph].include? f[:object] }
      fields.each do |field|
        # no error-checking for monograph stuff right now
        next if row[field[:field_name]].blank?
        is_multivalued = field[:multivalued]
        field_values = split_field_values_to_array(row[field[:field_name]], is_multivalued)
        attrs[field[:metadata_name]] = return_scalar_or_multivalued(field_values, is_multivalued)
      end
    end

    def data_for_asset(row_num, row, file_attrs)
      md = Redcarpet::Markdown.new(Redcarpet::Render::StripDown, space_after_headers: true)
      missing_fields_errors, controlled_vocab_errors, date_errors = Array.new(3) { [] }

      fields = METADATA_FIELDS.select { |f| [:universal, :file_set].include? f[:object] }
      fields.each do |field|
        if !row[field[:field_name]].blank?
          is_multivalued = field[:multivalued]
          field_values = split_field_values_to_array(row[field[:field_name]], is_multivalued)
          field_values = strip_markdown_from_array_of_values(field[:field_name], field_values, md)
          if field[:acceptable_values]
            downcase_restricted_values(field[:field_name], field_values)
            field_value_acceptable(field[:field_name], field[:acceptable_values], field_values, controlled_vocab_errors)
          end
          if field[:date_format]
            field_values = field_check_dates(field[:field_name], field_values, date_errors)
            next if field_values.blank?
          end
          file_attrs[field[:metadata_name]] = return_scalar_or_multivalued(field_values, is_multivalued)
        elsif field[:required] == true
          missing_fields_errors << field[:field_name]
        end
      end
      combine_field_errors(row_num, missing_fields_errors, controlled_vocab_errors, date_errors)
    end

    private

      def split_field_values_to_array(sheet_value, is_multivalued)
        is_multivalued == :yes_split ? Array(sheet_value.split(';')).map!(&:strip).reject(&:empty?) : Array(sheet_value.strip)
      end

      def strip_markdown_from_array_of_values(field_name, field_values, md)
        field_name == "Keywords" ? field_values.map! { |value| md.render(value).strip! } : field_values
      end

      def downcase_restricted_values(field_name, field_values)
        # when using controlled vocabularies make everything lowercase (Yes/No etc) except the crazy CC license names
        field_name == "Rights Granted - Creative Commons" ? field_values : field_values.map!(&:downcase)
      end

      def return_scalar_or_multivalued(field_values, is_multivalued)
        is_multivalued == :no ? field_values.first : field_values
      end

      def field_value_acceptable(field_name, acceptable_values, actual_values, controlled_vocab_errors)
        actual_values.each do |actual_value|
          unless acceptable_values.map(&:downcase).include? actual_value.downcase
            controlled_vocab_errors << field_name + ' - "' + actual_value + '"'
          end
        end
      end

      def field_check_dates(field_name, actual_values, date_errors)
        output_dates = []
        actual_values.each do |actual_value|
          fixed_date = output_date(actual_value)
          if !actual_value.blank? && actual_value.casecmp('perpetuity') != 0 && fixed_date.blank?
            date_errors << field_name + ': "' + actual_value + '"'
          elsif !fixed_date.blank?
            output_dates << fixed_date
          end
        end
        output_dates
      end

      def output_date(date_string)
        y = m = d = ''
        if date_string[/\d{4}-\d{2}-\d{2}/]
          y, m, d = date_string.split '-'
        elsif date_string[/\d{4}-\d{2}/]
          y, m = date_string.split '-'
          d = '01'
        elsif date_string[/\d{4}/]
          y = date_string
          m = d = '01'
        end
        return nil unless Date.valid_date?(y.to_i, m.to_i, d.to_i)
        y + '-' + m + '-' + d
      end

      def combine_field_errors(row_num, missing_fields_errors, controlled_vocab_errors, date_errors)
        message = "\n"
        message += '-' * 100 + "\nRow #{row_num}:"
        message += missing_fields_errors.empty? ? '' : "\nmissing required fields: \n" + missing_fields_errors.join(', ')
        message += controlled_vocab_errors.empty? ? '' : "\nunacceptable values for: \n" + controlled_vocab_errors.join(', ')
        message += date_errors.empty? ? '' : "\nthese dates cannot be padded to a YYYY-MM-DD value and will be discarded: \n" + date_errors.join(', ')
        # If every required metadata field is empty then assume it's the cover image. This is a pretty nasty assumption but I think it's the best way for now.
        if hide_errors(missing_fields_errors, controlled_vocab_errors, date_errors) then message = '' end
        message
      end

      def hide_errors(missing_fields_errors, controlled_vocab_errors, date_errors)
        no_errors = missing_fields_errors.empty? && controlled_vocab_errors.empty? && date_errors.empty?
        required_fields_count = METADATA_FIELDS.find_all { |fields| fields[:required] == true }.count
        no_required_fields_present = missing_fields_errors.count == required_fields_count
        no_errors || no_required_fields_present
      end
  end
end
