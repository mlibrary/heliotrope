# frozen_string_literal: true

require 'csv'

module Export
  class Exporter
    def initialize(monograph_id)
      @monograph = Monograph.find(monograph_id) if monograph_id.present?
    end

    def export
      return String.new if @monograph.blank?
      lines = []
      @monograph.ordered_members.to_a.each do |member|
        lines << metadata_field(member, :file_set)
      end
      lines << metadata_field(@monograph, :monograph)
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
        lines.each { |line| csv << line if line.present? }
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
        noid + file + METADATA_FIELDS
      end

      def metadata_field(item, object_type)
        line = []
        all_metadata.each do |field|
          metadata_name = field[:metadata_name]
          if (field[:object] != :universal && field[:object] != object_type) || item.public_send(metadata_name).blank?
            line << if object_type == :monograph && (['label', 'section_title'].include? metadata_name)
                      MONO_FILENAME_FLAG
                    end
            next
          end
          line << field_value(item, metadata_name, field[:multivalued])
        end
        line
      end

      def field_value(item, metadata_name, multivalued)
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
