module Import
  class RowData
    attr_reader :row, :attrs

    def data_for_monograph(row, attrs)
      title = Array(row['Title'].split(';')).map(&:strip)
      puts "  Monograph: #{title.first}"
      attrs['title'] = title
      attrs['creator_family_name'] = creator_family_name(row)
      attrs['creator_given_name'] = creator_given_name(row)
    end

    def data_for_asset(row_num, row, file_attrs)
      missing_fields_errors = []
      controlled_vocab_errors = []

      metadata_fields.each do |field|
        if !row[field['field_name']].blank?
          puts "#{field['field_name']}: " + row[field['field_name']]
          if field['acceptable_values']
            field_value_acceptable(field, row, controlled_vocab_errors)
          end
          file_attrs[field['metadata_name']] = if row[field['multi_value'] == true]
                                                 Array(row[field['field_name']].split(';')).map(&:strip)
                                               else
                                                 Array(row[field['field_name']].strip)
                                               end
        elsif field['required'] == true
          # add to array of missing stuff
          # missing_required_fields.add(row[field['field_name']])
          missing_fields_errors << field['field_name']
        end
      end

      file_attrs['creator_family_name'] = creator_family_name(row)
      file_attrs['creator_given_name'] = creator_given_name(row)

      combine_field_errors(row_num, missing_fields_errors, controlled_vocab_errors)
    end

    def field_value_acceptable(field, row, controlled_vocab_errors)
      unless field['acceptable_values'].include? row[field['field_name']]
        controlled_vocab_errors << field['field_name'] + ' - "' + row[field['field_name']] + '"'
      end
    end

    def creator_family_name(row)
      return unless row['Primary Creator Last Name']
      row['Primary Creator Last Name'].strip
    end

    def creator_given_name(row)
      return unless row['Primary Creator First Name']
      row['Primary Creator First Name'].strip
    end

    def combine_field_errors(row_num, missing_fields_errors, controlled_vocab_errors)
      message = ''
      message += "\n\nRow #{row_num} has errors:\n" unless missing_fields_errors.empty? && controlled_vocab_errors.empty?
      unless missing_fields_errors.empty?
        message += "missing required fields: \n" + missing_fields_errors.join(', ')
      end
      unless controlled_vocab_errors.empty?
        message += "\nunacceptable values for: \n" + controlled_vocab_errors.join(', ')
      end
      message
    end

    def metadata_fields
      [
        { 'field_name' => 'Title', 'metadata_name' => 'title', 'required' => true, 'multi_value' => false },
        { 'field_name' => 'Caption', 'metadata_name' => 'caption', 'required' => true, 'multi_value' => true },
        { 'field_name' => 'Alternative Text', 'metadata_name' => 'alt_text', 'required' => true, 'multi_value' => true },
        { 'field_name' => 'Resource Type', 'metadata_name' => 'content_type', 'required' => true, 'multi_value' => false, 'acceptable_values' => ['audio', 'image', 'dataset', 'table', '3D model', 'text', 'video'] },
        { 'field_name' => 'Copyright Holder', 'metadata_name' => 'copyright_holder', 'required' => true, 'multi_value' => true },
        { 'field_name' => 'Externally Hosted Resource', 'metadata_name' => 'external_resource', 'required' => true, 'multi_value' => true },
        { 'field_name' => 'Persistent ID', 'metadata_name' => 'persistent_id', 'required' => true, 'multi_value' => true }
      ]
    end
  end
end
