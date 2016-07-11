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

      # TODO: raise an error if file name is missing and it's not explicitly an external resource
      # ... not going to do this until I know how to attach it as an external resource!
      #
      # if row['File Name'].blank? && row['Externally-Hosted Resource'] != 'yes'
      #   puts "Row #{row_num}: File name missing and not external resource!"
      #   next
      # end

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
        # for now leave File Name separate, but eventually when external resources are figured out it should go in here too with required => false
        # { 'field_name' => 'File Name', 'metadata_name' => 'title', 'required' => true, 'multi_value' => false },
        { 'field_name' => 'Title', 'metadata_name' => 'title', 'required' => true, 'multi_value' => false },
        { 'field_name' => 'Resource Type', 'metadata_name' => 'resource_type', 'required' => true, 'multi_value' => false, 'acceptable_values' => ['audio', 'image', 'dataset', 'table', '3D model', 'text', 'video'] },
        { 'field_name' => 'Externally Hosted Resource', 'metadata_name' => 'external_resource', 'required' => true, 'multi_value' => true, 'acceptable_values' => ['yes', 'no'] },
        { 'field_name' => 'Caption', 'metadata_name' => 'caption', 'required' => true, 'multi_value' => true },
        { 'field_name' => 'Alternative Text', 'metadata_name' => 'alt_text', 'required' => true, 'multi_value' => true },
        # { 'field_name' => 'Book and Platform (BP) or Platform-only (P)', 'metadata_name' => '', 'required' => true, 'multi_value' => true, 'acceptable_values' => ['BP', 'P'] },
        { 'field_name' => 'Copyright Holder', 'metadata_name' => 'copyright_holder', 'required' => true, 'multi_value' => true },
        # { 'field_name' => 'Allow High-Res Display?', 'metadata_name' => '', 'required' => true, 'multi_value' => false, 'acceptable_values' => ['yes', 'no', 'Not hosted on the platform'], 'acceptable_values' => ['yes', 'no', 'Not hosted on the platform'] },
        # { 'field_name' => 'Allow Download?', 'metadata_name' => '', 'required' => true, 'multi_value' => false, 'acceptable_values' => ['yes', 'no', 'Not hosted on the platform'] },
        # { 'field_name' => 'Copyright Status', 'metadata_name' => '', 'required' => true, 'multi_value' => false, 'acceptable_values' => ['in copyright', 'public domain', 'status unknown'] },
        # { 'field_name' => 'Rights Granted', 'metadata_name' => '', 'required' => false, 'multi_value' => false },
        { 'field_name' => 'Rights Granted - Creative Commons',
          'metadata_name' => '',
          'required' => false,
          'multi_value' => false,
          'acceptable_values' => [
            'Creative Commons Attribution license, 3.0 Unported',
            'Creative Commons Attribution-NoDerivatives license, 3.0 Unported',
            'Creative Commons Attribution-NonCommercial-NoDerivatives license, 3.0 Unported',
            'Creative Commons Attribution-NonCommercial license, 3.0 Unported',
            'Creative Commons Attribution-NonCommercial-ShareAlike license, 3.0 Unported',
            'Creative Commons Attribution-ShareAlike license, 3.0 Unported',
            'Creative Commons Zero license (implies pd)',
            'Creative Commons Attribution 4.0 International license',
            'Creative Commons Attribution-NoDerivatives 4.0 International license',
            'Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International license',
            'Creative Commons Attribution-NonCommercial 4.0 International license',
            'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International license',
            'Creative Commons Attribution-ShareAlike 4.0 International license'] },
        { 'field_name' => 'Permissions Expiration Date', 'metadata_name' => 'persistent_id', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'After Expiration: Allow Display?', 'metadata_name' => '', 'required' => false, 'multi_value' => true, 'acceptable_values' => ['none', 'high-res', 'low-res', 'Not hosted on the platform'] },
        { 'field_name' => 'After Expiration: Allow Download?', 'metadata_name' => '', 'required' => false, 'multi_value' => true, 'acceptable_values' => ['yes', 'no', 'Not hosted on the platform'] },
        { 'field_name' => 'Credit Line', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Holding Contact', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        # { 'field_name' => 'Persistent ID - Display on Platform', 'metadata_name' => '', 'required' => true, 'multi_value' => false, 'acceptable_values' => ['yes', 'no'] },
        { 'field_name' => 'Persistent ID - XML for CrossRef', 'metadata_name' => '', 'required' => false, 'multi_value' => true, 'acceptable_values' => ['yes', 'no'] },
        { 'field_name' => 'Persistent ID - Handle', 'metadata_name' => '', 'required' => false, 'multi_value' => true, 'acceptable_values' => ['yes', 'no'] },
        { 'field_name' => 'Content Type', 'metadata_name' => 'content_type', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Primary Creator Role', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Additional Creator(s)', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Sort Date', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Display Date', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Description', 'metadata_name' => 'description', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Keywords', 'metadata_name' => 'keywords', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Language', 'metadata_name' => 'language', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Transcript', 'metadata_name' => '', 'required' => false, 'multi_value' => true },
        { 'field_name' => 'Translation', 'metadata_name' => '', 'required' => false, 'multi_value' => true }
      ]
    end
  end
end
