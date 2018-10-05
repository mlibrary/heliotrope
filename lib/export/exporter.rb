# frozen_string_literal: true

require 'csv'

module Export
  class Exporter
    attr_reader :all_metadata

    def initialize(monograph_id, columns = :all)
      @monograph = Monograph.find(monograph_id) if monograph_id.present?
      @columns = columns
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

    def extract # rubocop:disable Metrics/CyclomaticComplexity
      return if @monograph.blank?
      base = File.join(".", "extract")
      FileUtils.mkdir(base) unless Dir.exist?(base)
      press = File.join(base, @monograph.press.to_s)
      FileUtils.mkdir(press) unless Dir.exist?(press)
      path = File.join(press, @monograph.id.to_s)
      if Dir.exist?(path)
        puts "Overwrite #{path} directory? (Y/n):"
        return unless /y/i.match?(STDIN.getch)
        FileUtils.rm_rf(path)
      end
      FileUtils.mkdir(path)
      manifest = File.new(File.join(path, @monograph.id.to_s + ".csv"), "w")
      manifest << export
      manifest.close
      @monograph.ordered_members.to_a.each do |member|
        next unless member.original_file
        filename = CGI.unescape(member.original_file.file_name.first)
        file = File.new(File.join(path, filename), "wb")
        file.write(member.original_file.content.force_encoding("utf-8"))
        file.close
      end
    end

    def monograph_row
      metadata_row(@monograph, :monograph)
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

    private

      def all_metadata
        return @all_metadata if @all_metadata.present?
        # Export the object id in the first column of the exported CSV file (required doesn't matter here)
        noid = [{ object: :universal, field_name: 'NOID', metadata_name: 'id', required: true, multivalued: :no }]
        # We need the file name in the exported CSV file (required doesn't matter here)
        # Ideally this should be moved to metadata_fields.rb and the importer would be refactored (maybe)
        # Aside: In the absence of a title the file name is used
        file = [{ object: :file_set, field_name: 'File Name', metadata_name: 'label', required: true, multivalued: :no }]
        # We want the url in the exported CSV file (required doesn't matter here)
        url = [{ object: :universal, field_name: 'Link', metadata_name: 'url', required: true, multivalued: :no }]

        @all_metadata = if @columns == :monograph
                          noid + url + METADATA_FIELDS.select { |f| %i[universal monograph].include? f[:object] }
                        else
                          noid + file + url + METADATA_FIELDS
                        end
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
          # Any intended order within a multi-valued field is lost after having been stored in an...
          # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically on export.
          # Items whose order must be preserved should never be stored in an `ActiveTriples::Relation`.
          item.public_send(metadata_name).sort.join('; ')
        elsif multivalued == :yes
          # this is a multi-valued field but we're only using it to hold one value
          item.public_send(metadata_name).first
        elsif multivalued == :yes_multiline
          # this is a multi-valued field but we're only using the first one to hold a string containing...
          # ordered, newline-separated values. Need such to be semi-colon-separeated in a cell once again
          item.public_send(metadata_name).first.split(/\r?\n/).reject(&:blank?).join('; ')
        else
          item.public_send(metadata_name)
        end
      end
  end
end
