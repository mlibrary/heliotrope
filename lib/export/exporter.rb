# frozen_string_literal: true

require 'csv'

module Export
  class Exporter
    attr_reader :all_metadata, :monograph, :monograph_presenter, :columns

    def initialize(monograph_id, columns = :all)
      @monograph = Sighrax.from_noid(monograph_id)
      @columns = columns
    end

    def export
      return String.new if monograph.instance_of?(Sighrax::NullEntity)

      rows = []
      monograph.children.each do |member|
        member_presenter = Sighrax.hyrax_presenter(member)
        rows << metadata_row(member_presenter, monograph_presenter.representative_id)
      end

      rows << metadata_row(monograph_presenter)
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
        rows.each { |row| csv << row if row.present? }
      end

      buffer
    end

    def extract(use_dir = nil, now = false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return unless monograph.valid?

      job_path = nil

      if use_dir
        path = "#{use_dir}/"
        job_path = if path[0] == '/'
                     path
                   else
                     File.join(Dir.pwd, path)
                   end
      else
        base = File.join(".", "extract")
        FileUtils.mkdir(base) unless Dir.exist?(base)
        press = File.join(base, monograph_presenter.subdomain.to_s)
        FileUtils.mkdir(press) unless Dir.exist?(press)
        path = File.join(press, monograph.noid.to_s)
        if Dir.exist?(path)
          puts "Overwrite #{path} directory? (Y/n):"
          return unless /y/i.match?(STDIN.getch)

          FileUtils.rm_rf(path)
        end
        FileUtils.mkdir(path)
        job_path = File.join(Dir.pwd, path)
      end

      manifest = File.new(File.join(path, monograph.noid.to_s + ".csv"), "w")
      manifest << export
      manifest.close

      if now
        OutputMonographFilesJob.perform_now(monograph.noid, job_path)
      else
        OutputMonographFilesJob.perform_later(monograph.noid, job_path)
      end
    end

    def monograph_row
      metadata_row(monograph_presenter)
    end

    def blank_csv_sheet
      buffer = String.new
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
      end
      buffer
    end

    def write_csv_header_rows(csv)
      row1 = []
      row2 = []
      all_metadata.each do |field|
        row1 << field[:field_name]
        # don't want to deal with the huge instruction/description fields in test
        row2 << (Rails.env.test? ? 'instruction placeholder' : field[:description])
      end
      csv << row1 << row2
    end

    private

      def monograph_presenter
        @monograph_presenter ||= Sighrax.hyrax_presenter(monograph)
      end

      def all_metadata
        return @all_metadata if @all_metadata.present?

        @all_metadata = if @columns == :monograph
                          (ADMIN_METADATA_FIELDS + METADATA_FIELDS).select { |f| %i[universal monograph].include? f[:object] }
                        else
                          ADMIN_METADATA_FIELDS + METADATA_FIELDS + FILE_SET_FLAG_FIELDS
                        end
      end

      def metadata_row(item, parent_rep = nil)
        row = []
        return row if item.instance_of?(Sighrax::NullEntity)

        object_type = item.has_model == 'Monograph' ? :monograph : :file_set
        all_metadata.each do |field|
          row << metadata_field_value(item, object_type, field, parent_rep)
        end
        row
      end

      def metadata_field_value(item, object_type, field, parent_rep) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # this gets around the FileSet's label not matching the original_file's name post-versioning
        # safe navigation is important as we have fileless FileSets in production and specs
        return file_name(item) if object_type == :file_set && field[:field_name] == 'File Name'
        return representative_kind_or_cover(item, parent_rep) if object_type == :file_set && field[:field_name] == 'Representative Kind'
        return item_url(item, object_type) if field[:object] == :universal && field[:field_name] == 'Link'
        return file_set_embed_code(item) if object_type == :file_set && field[:field_name] == 'Embed Code'
        return field_value(item, field[:metadata_name], field[:multivalued]) if field[:object] == :universal || field[:object] == object_type
        return MONO_FILENAME_FLAG if object_type == :monograph && (['label', 'section_title'].include? field[:metadata_name])
      end

      def file_name(item)
        # ensure no entry appears in the "File Name" column for "fileless FileSets"
        fileless_fileset(item) ? nil : CGI.unescape(item&.original_name&.first)
      end

      def fileless_fileset(file_set)
        file_set.external_resource_url.present? || file_set.file_size.blank? || file_set.file_size.zero?
      end

      def representative_kind_or_cover(item, parent_rep)
        # I think we can ignore thumbnail_id, should always be the same as representative_id for us
        return 'cover' if parent_rep == item.id

        FeaturedRepresentative.where(file_set_id: item.id, work_id: monograph.noid).first&.kind
      end

      def item_url(item, item_type)
        link = if item_type == :monograph
                 Rails.application.routes.url_helpers.hyrax_monograph_url(item.id)
               else
                 Rails.application.routes.url_helpers.hyrax_file_set_url(item.id)
               end
        '=HYPERLINK("' + link + '")'
      end

      def file_set_embed_code(file_set)
        file_set.embed_code
      end

      def field_value(item, metadata_name, multivalued) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        return if item.public_send(metadata_name).blank?

        value = Array.wrap(item.public_send(metadata_name))

        if multivalued == :yes_split
          # Any intended order within a multi-valued field is lost after having been stored in an...
          # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically on export.
          # Items whose order must be preserved should never be stored in an `ActiveTriples::Relation`.
          value.sort.join('; ')
        elsif multivalued == :yes
          # this is a multi-valued field but we're only using it to hold one value
          # Because of TitlePresenter, the title value returned by the presenter will be HTML
          # I don't want to convert HTML to Markdown here, so taking title from the Solr doc
          case metadata_name
          when 'title'
            return item.solr_document['title_tesim'].first
          else
            return value.first
          end
        elsif multivalued == :yes_multiline
          # note1: this is a multi-valued field but we're only using the first one to hold a string containing...
          #        ordered, newline-separated values. Need such to be semi-colon-separated in a cell once again
          # note2: now making `item` a presenter for speed. Given that there was no clean value on the Solr doc...
          #        these were specifically indexed for the exporter
          case metadata_name
          when 'creator'
            return item.solr_document['importable_creator_ss']
          when 'contributor'
            return item.solr_document['importable_contributor_ss']
          else
            # shouldn't happen as creator/contributor are the only :yes_multiline fields
            return value.first
          end
        else
          # https://tools.lib.umich.edu/jira/browse/HELIO-2321
          metadata_name == 'doi' ? 'https://doi.org/' + value.first : value.first
        end
      end
  end
end
