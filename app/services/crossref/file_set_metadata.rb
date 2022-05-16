# frozen_string_literal: true

module Crossref
  class FileSetMetadata
    attr_reader :work, :document, :component_file, :presenters, :file_sets_to_save

    def initialize(work_noid)
      @work = Sighrax.hyrax_presenter(Sighrax.from_noid(work_noid))
      raise "Work #{work.id} does not have a DOI" if @work.doi.blank?
      raise "Press #{work.subdomain} can not make automatic DOIs" unless Press.where(subdomain: @work.subdomain).first&.create_dois?

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
        next if monograph_representative?(presenter)
        fragment = Nokogiri::XML.fragment(@component_file)
        fragment.at_css('title').content = presenter.page_title
        fragment.at_css('description').content = description(presenter)
        if presenter.external_resource?
          fragment.at_css('format').remove_attribute('mime_type')
          fragment.at_css('format').content = 'Metadata record for externally-hosted component'
        else
          fragment.at_css('format').attribute('mime_type').value = mime_type(presenter.mime_type)
        end
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

    def mime_type(mime)
      # Why can't you have "text/csv" as a valid mime_type in crossref?
      # Who knows? But you can't, sadly.
      # http://data.crossref.org/reports/help/schema_doc/doi_resources4.3.6/4_3_6.html#mime_type.atts
      # https://tools.lib.umich.edu/jira/browse/HELIO-3163
      # This is of course not right, but what can you do?
      return "application/vnd.ms-excel" if mime == "text/csv"
      # HELIO-3378 has another one of these. There are very few acceptable audio mime types to choose from only these:
      # audio/basic, audio/32kadpcm, audio/mpeg, audio/parityfec, audio/MP4A-LATM, audio/mpa-robust
      # so I don't know what's right exactly. This just seems wrong.
      return "audio/basic" if mime == "audio/x-wave"
      # HELIO-4183
      return "video/mp4" if mime == "video/x-m4v"
      mime
    end

    def monograph_doi_is_registered?
      # See HELIO-3378. This *really* shouldn't happen, but it did once, so we need this check.
      # This could totally block. Move to a Job? I dunno. We'll see how it goes for a while I guess.
      request = Typhoeus::Request.new(Crossref::Config.load_config['search_url'] + "/#{@work.doi}")
      resp = request.run
      return false if resp.failure?
      return false if resp.code == "404"
      true
    end

    private

      def save_dois_to_file_sets
        # Can you imagine how long this would take for a work with 2000+ file_sets?
        # It could be hours. Pass to a job I guess.
        #
        # Also: HELIO-3378 we're NOT going to save resource/file_set DOIs if the Monograph
        # has an UNREGISTERED DOI. We're still going to go through the steps and run the submission,
        # but that submission will FAIL at Crossref since the Monograph does not have a REGISTERED DOI.
        # So: if the monograph DOI is unregistered, still run the submission and let it fail.
        # But don't save the resource DOIs. The error will be obvious in the crossref_log, so
        # once the monograph doi is sorted out this whole file_set_metadata DOI creation process
        # will need to be re-run. Which is fine.
        BatchSaveJob.perform_later(file_sets_to_save) if monograph_doi_is_registered?
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
        return false if presenter.webgl? # "webgl" featured reps get a DOI now, HELIO-4214
        return true if presenter.featured_representative? # other featured reps do not
        return true if presenter.id == presenter.parent.representative_id # the cover does not
        false
      end
  end
end
