# frozen_string_literal: true

require 'csv'
require 'io/console'

module Export
  class Exporter
    attr_reader :all_metadata, :monograph, :monograph_presenter, :columns

    def initialize(monograph_id, columns = :all)
      @monograph = if monograph_id.blank?
                     # the use case here is dumping metadata rows for o individual objects in rails/rake tasks,...
                     # with no parent monograph involved
                     nil
                   else
                     begin
                       Monograph.find(monograph_id)
                     rescue ActiveFedora::ObjectNotFoundError, Ldp::Gone
                       nil
                     end
                   end
      @columns = columns
    end

    def export
      return String.new(encoding: "UTF-8") if monograph.blank?

      rows = []
      monograph.ordered_members.to_a.each do |member|
        rows << metadata_row(member, monograph_presenter.representative_id)
      end

      rows << metadata_row(monograph)
      buffer = String.new(encoding: "UTF-8")
      CSV.generate(buffer) do |csv|
        write_csv_header_rows(csv)
        rows.each { |row| csv << row if row.present? }
      end

      buffer
    end

    def extract(use_dir = nil, now = false) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return if monograph.blank?

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
        path = File.join(press, monograph.id.to_s)
        if Dir.exist?(path)
          puts "Overwrite #{path} directory? (Y/n):"
          return unless /y/i.match?(STDIN.getch)

          FileUtils.rm_rf(path)
        end
        FileUtils.mkdir(path)
        job_path = File.join(Dir.pwd, path)
      end

      manifest = File.new(File.join(path, "manifest.csv"), "w")
      manifest << export
      manifest.close

      if now
        OutputMonographFilesJob.perform_now(monograph.id, job_path)
      else
        OutputMonographFilesJob.perform_later(monograph.id, job_path)
      end
    end

    def monograph_row
      metadata_row(monograph)
    end

    def blank_csv_sheet
      buffer = +''
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

    # made this a public method purely for dumping metadata rows for o individual objects in rails/rake tasks,...
    # with no parent monograph involved
    def metadata_row(item, parent_rep = nil)
      row = []
      return row if item.blank?

      object_type = item.has_model == ['Monograph'] ? :monograph : :file_set
      file_set_presenter = Hyrax::PresenterFactory.build_for(ids: [item.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first if object_type == :file_set
      all_metadata.each do |field|
        row << metadata_field_value(item, object_type, field, parent_rep, file_set_presenter)
      end
      row
    end

    private

      def monograph_presenter
        @monograph_presenter ||= Hyrax::PresenterFactory.build_for(ids: [monograph.id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first
      end

      def all_metadata
        return @all_metadata if @all_metadata.present?

        @all_metadata = if @columns == :monograph
                          fields = ADMIN_METADATA_FIELDS + METADATA_FIELDS
                          (fields).select { |f| %i[universal monograph].include? f[:object] }
                        else
                          # the Exporter can be instantiated with no `monograph_id`, to output individual object rows.
                          # It doesn't make sense to output the FeaturedRepresentative relationship in that case,...
                          # and no script that uses such object-editing output can set FeaturedRepresentative anyway.
                          if monograph.present?
                            ADMIN_METADATA_FIELDS + METADATA_FIELDS + FILE_SET_FLAG_FIELDS
                          else
                            ADMIN_METADATA_FIELDS + METADATA_FIELDS
                          end
                        end
      end

      def metadata_field_value(item, object_type, field, parent_rep, file_set_presenter = nil) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        # this gets around the FileSet's label not matching the original_file's name post-versioning
        # safe navigation is important as we have fileless FileSets in production and specs
        return file_name(file_set_presenter) if object_type == :file_set && field[:field_name] == 'File Name'
        return representative_kind_or_cover(item, parent_rep) if object_type == :file_set && field[:field_name] == 'Representative Kind'
        return item_url(item, object_type) if field[:object] == :universal && field[:field_name] == 'Link'
        return file_set_presenter&.embed_code if object_type == :file_set && field[:field_name] == 'Embed Code'
        return published?(item) if field[:field_name] == 'Published?'
        return field_value(item, field[:metadata_name], field[:multivalued]) if field[:object] == :universal || field[:object] == object_type
        return MONO_FILENAME_FLAG if object_type == :monograph && (['label', 'section_title'].include? field[:metadata_name])
      end

      def file_name(file_set_presenter)
        # ensure no entry appears in the "File Name" column for "fileless FileSets"
        fileless_fileset(file_set_presenter) ? nil : CGI.unescape(file_set_presenter&.original_name&.first)
      end

      def fileless_fileset(file_set_presenter)
        file_set_presenter.external_resource_url.present? || file_set_presenter.file_size.blank? || file_set_presenter.file_size.zero?
      end

      def representative_kind_or_cover(item, parent_rep)
        # I think we can ignore thumbnail_id, should always be the same as representative_id for us
        return 'cover' if parent_rep == item.id

        FeaturedRepresentative.where(file_set_id: item.id, work_id: monograph.id).first&.kind
      end

      def item_url(item, item_type)
        link = if item_type == :monograph
                 Rails.application.routes.url_helpers.hyrax_monograph_url(item.id)
               else
                 Rails.application.routes.url_helpers.hyrax_file_set_url(item.id)
               end
        '=HYPERLINK("' + link + '")'
      end

      def published?(item)
        item.visibility == 'open'
      end

      def field_value(item, metadata_name, multivalued) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        value = item.public_send(metadata_name)
        return if value.blank?

        if multivalued == :yes_split
          # Any intended order within a multi-valued field is lost after having been stored in an...
          # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically on export.
          # Items whose order must be preserved should never be stored in an `ActiveTriples::Relation`.
          value.to_a.sort.join('; ')
        elsif multivalued == :yes
          # this is a multi-valued field but we're only using it to hold one value
          value.first
        elsif multivalued == :yes_multiline
          # note: this is a multi-valued field but we're only using the first one to hold a string containing...
          #       ordered, newline-separated values. Need such to be semi-colon-separated in a cell once again
          value.first.split(/\r\n?|\n/).reject(&:blank?).join('; ')
        else
          # https://tools.lib.umich.edu/jira/browse/HELIO-2321
          metadata_name == 'doi' ? 'https://doi.org/' + value : value
        end
      end
  end
end
