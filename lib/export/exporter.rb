require 'csv'

module Export
  class Exporter
    attr_reader :monographs

    def initialize(monograph_id)
      @monographs = if monograph_id == 'all'
                      Monograph.all
                    else
                      [Monograph.find(monograph_id)]
                    end
    end

    def run
      output_files = []
      monographs.to_a.each do |m|
        lines = []
        m.ordered_members.to_a.each do |mm|
          lines << metadata_field(mm, :file_set)
        end
        lines << metadata_field(m, :monograph)
        output_filesets_to_csv(m.title.first, lines, output_files)
      end
      output_files
    end

    private

      def all_metadata
        # we need the file name in the exported CSV file (required doesn't matter here)
        # ideally this should be moved to metadata_fields.rb and the importer would be refactored (maybe)
        # aside: in the absence of a title, the filename is also used for that
        file = [{ object: :file_set, field_name: 'File Name', metadata_name: 'label', required: true, multivalued: :no }]
        file + METADATA_FIELDS
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
        value = if multivalued == :yes_split
                  # TODO: right now we have lost any intended order in our multi-value fields, so I'm sorting them
                  # alphabetically on export. This is convenient for testing but we'll have to address the problem
                  # eventually *and* possibly fix production data too
                  item.public_send(metadata_name).sort.join('; ')
                elsif multivalued == :yes
                  item.public_send(metadata_name).first
                else
                  item.public_send(metadata_name)
                end
        metadata_name == 'exclusive_to_platform' ? value.gsub('no', 'BP').gsub('yes', 'P') : value
      end

      def output_filesets_to_csv(mono_title, lines, output_files)
        if lines.blank?
          puts 'no output generated'
        else
          # create a neatish monograph title plus timestamp filename...
          # for starters throw away any subtitles, which follow a ':'
          prefix = mono_title.split(':')[0].squish.downcase.tr(" ", "_").gsub(/[^\w\.]/, '')
          filename = '/tmp/' + prefix + '_' + Time.now.strftime('%Y%m%d%H%M%S') + '.csv'
          CSV.open(filename, 'wb') do |csv|
            write_csv_header_rows(csv)
            lines.each { |line| csv << line unless line.blank? }
          end
          puts 'output written to ' + filename
          output_files << filename
        end
      end

      def write_csv_header_rows(csv)
        row1 = []
        row2 = []
        all_metadata.each do |field|
          row1 << field[:field_name]
          row2 << nil
        end
        csv << row1 << row2
      end

      def convert_exclusivity_field(field_name, field_values)
        change_values = { 'no' => 'BP', 'yes' => 'P' }
        field_name == 'Book and Platform (BP) or Platform-only (P)' ? field_values.map! { |value| change_values[value.upcase] } : field_values
      end
  end
end
