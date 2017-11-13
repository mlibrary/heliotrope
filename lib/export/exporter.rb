# frozen_string_literal: true

require 'csv'

module Export
  class Exporter
    def initialize(monograph_id)
      @monograph = Monograph.find(monograph_id) if monograph_id.present?
    end

    def export
      return String.new if @monograph.blank?
      rows = []
      @monograph.ordered_members.to_a.each do |member|
        rows << metadata_row(member, :file_set)
      end
      rows << metadata_row(@monograph, :monograph)
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
        rows.each { |row| csv << row if row.present? }
      end
      buffer
    end

    private

      def all_metadata
        # Export the object id in the first column of the exported CSV file (required doesn't matter here)
        noid = [{ object: :universal, field_name: 'NOID', metadata_name: 'id', required: true, multivalued: :no }]
        # We need the file name in the exported CSV file (required doesn't matter here)
        # Ideally this should be moved to metadata_fields.rb and the importer would be refactored (maybe)
        # Aside: In the absence of a title the file name is used
        file = [{ object: :file_set, field_name: 'File Name', metadata_name: 'label', required: true, multivalued: :no }]
        # We want the url in the exported CSV file (required doesn't matter here)
        url = [{ object: :universal, field_name: 'Link', metadata_name: 'url', required: true, multivalued: :no }]
        noid + file + url + METADATA_FIELDS
      end

      def metadata_row(item, object_type)
        row = []
        all_metadata.each do |field|
          row << metadata_field_value(item, object_type, field)
        end
        row
      end

      def metadata_field_value(item, object_type, field) # rubocop:disable Metrics/CyclomaticComplexity
        return item_url(item, object_type) if field[:object] == :universal && field[:field_name] == 'Link'
        return field_value(item, field[:metadata_name], field[:multivalued]) if field[:object] == :universal || field[:object] == object_type
        return MONO_FILENAME_FLAG if object_type == :monograph && (['label', 'section_title'].include? field[:metadata_name])
      end

      def item_url(item, item_type)
        link = if item_type == :monograph
                 Rails.application.routes.url_helpers.hyrax_monograph_url(item)
               else
                 Rails.application.routes.url_helpers.hyrax_file_set_url(item)
               end
        '=HYPERLINK("' + link + '")'
      end

      def field_value(item, metadata_name, multivalued)
        return if item.public_send(metadata_name).blank?
        if multivalued == :yes_split
          # TODO: right now we have lost any intended order in our multi-value fields, so I'm sorting them
          # alphabetically on export. This is convenient for testing but we'll have to address the problem
          # eventually *and* possibly fix production data too
          item.public_send(metadata_name).sort.join('; ')
        elsif multivalued == :yes
          item.public_send(metadata_name).first
        else
          item.public_send(metadata_name)
        end
      end

      def write_csv_header_rows(csv)
        row1 = []
        row2 = []
        all_metadata.each do |field|
          row1 << field[:field_name]
          row2 << 'instruction placeholder'
        end
        csv << row1 << row2
      end
  end
end
