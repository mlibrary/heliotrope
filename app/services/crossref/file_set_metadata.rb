# frozen_string_literal: true

module Crossref
  class FileSetMetadata
    attr_reader :work, :document, :component_file, :presenters, :file_sets_to_save

    def initialize(work_noid)
      @work = Sighrax.hyrax_presenter(Sighrax.factory(work_noid))
      raise "Work #{work.id} does not have a DOI" if @work.doi.blank?

      @document = Nokogiri::XML(File.read(Rails.root.join("config", "crossref", "file_set_metadata_template.xml")))
      @component_file = File.read(Rails.root.join("config", "crossref", "component_template.xml"))

      @presenters = presenters_for(Hyrax::FileSetPresenter, @work.solr_document['ordered_member_ids_ssim'])

      @file_sets_to_save = {}
    end

    def build
      doi_batch_id
      set_timestamp
      parent_doi
      components
      # This might not be the time to save DOIs to the FileSets
      # Instead maybe wait for the submission to succeed and then
      # do it? We could put @file_sets_to_save into the cache (or something)
      # and pick it up later?
      save_dois_to_file_sets
      document
    end

    def doi_batch_id
      document.at_css('doi_batch_id').content = "#{work.subdomain}-#{work.id}-filesets-#{timestamp}"
    end

    def set_timestamp
      document.at_css('timestamp').content = timestamp
    end

    def parent_doi
      document.at_css('sa_component').attribute('parent_doi').value = work.doi
    end

    def components
      presenters.each_with_index do |presenter, index|
        next if presenter.external_resource?
        next if monograph_representative?(presenter)
        fragment = Nokogiri::XML.fragment(@component_file)
        fragment.at_css('title').content = presenter.page_title
        fragment.at_css('description').content = description(presenter)
        fragment.at_css('format').attribute('mime_type').value = presenter.mime_type
        fragment.at_css('doi').content = doi(presenter, index)
        fragment.at_css('resource').content = presenter.handle_url
        document.at_css('component_list') << fragment
      end
    end

    # See HELIO-2739
    def description(presenter)
      desc = presenter.description.first || presenter.caption.first || ""
      desc += " #{presenter.creator.join(', ')}." if presenter.creator.present?
      desc += " #{presenter.contributor.join(', ')}." if presenter.contributor.present?
      desc
    end

    def doi(presenter, index)
      # If there's a DOI already populated, regardless of whether it is actually
      # registered with Crossref, use that. This means people can put DOIs into
      # the importer metadata and this will use them.
      return presenter.doi if presenter.doi.present?

      # Otherwise make a DOI based on the file_sets's position in ordered_members.
      # This is fragile and probably a bad idea.
      # What's a better way to generate predicable DOIs?
      file_set_doi = "#{work.doi}.cmp.#{index + 1}"
      file_sets_to_save[presenter.id] = { doi: file_set_doi }
      file_set_doi
    end

    private

      def save_dois_to_file_sets
        # Can you imagine how long this would take for a work with 2000+ file_sets?
        # It could be hours. Pass to a job I guess.
        BatchSaveJob.perform_later(file_sets_to_save)
      end

      def presenters_for(hyrax_presenter, noids)
        presenters = []
        until noids.empty?
          Hyrax::PresenterFactory.build_for(ids: noids.shift(999), presenter_class: hyrax_presenter, presenter_args: nil).map do |p|
            presenters << p
          end
        end
        presenters
      end

      def timestamp
        Time.current.strftime("%Y%m%d%H%M%S")
      end

      def monograph_representative?(presenter)
        return true if presenter.epub?
        return true if presenter.mobi?
        return true if presenter.pdf_ebook?
        return true if presenter.id == presenter.parent.representative_id
        false
      end
  end
end
