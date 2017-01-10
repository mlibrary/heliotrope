module CurationConcerns
  class FileSetPresenter
    include TitlePresenter
    include AnalyticsPresenter
    include OpenUrlPresenter
    include ModelProxy
    include PresentsAttributes
    include Rails.application.routes.url_helpers

    attr_accessor :solr_document, :current_ability, :request, :monograph_presenter

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    delegate :resource_type, :caption, :alt_text, :description, :copyright_holder,
             :content_type, :creator, :creator_full_name, :contributor, :date_created,
             :keywords, :relation, :publisher, :language, :date_uploaded,
             :rights, :embargo_release_date, :lease_expiration_date, :depositor, :tags,
             :title_or_label, :external_resource, :book_needs_handles, :section_title, :section_id,
             :allow_download, :allow_hi_res, :copyright_status, :rights_granted,
             :rights_granted_creative_commons, :exclusive_to_platform, :permissions_expiration_date,
             :allow_display_after_expiration, :allow_download_after_expiration, :credit_line,
             :holding_contact, :ext_url_doi_or_handle, :doi, :hdl, :use_crossref_xml, :primary_creator_role,
             :display_date, :sort_date, :search_year, :transcript, :translation, :file_format,
             :creator_given_name, :creator_family_name,
             to: :solr_document

    def subdomain
      Array(solr_document['press_tesim']).first
    end

    def press
      Array(solr_document['press_name_ssim']).first
    end

    def press_logo
      Press.find_by(subdomain: subdomain).logo_path
    end

    def press_url
      Press.find_by(subdomain: subdomain).press_url
    end

    def section_title
      Array(solr_document['section_title_tesim']).first
    end

    def section_id
      Array(solr_document['section_id_ssim']).first
    end

    def monograph_id
      Array(solr_document['monograph_id_ssim']).first
    end

    def monograph
      @monograph_presenter ||= PresenterFactory.build_presenters([monograph_id], MonographPresenter, current_ability).first
    end

    def subjects
      monograph.subject
    end

    def previous_id?
      monograph.previous_file_sets_id? id
    end

    def previous_id
      monograph.previous_file_sets_id id
    end

    def next_id?
      monograph.next_file_sets_id? id
    end

    def next_id
      monograph.next_file_sets_id id
    end

    def link_name
      current_ability.can?(:read, id) ? Array(solr_document['label_tesim']).first : 'File'
    end

    def citable_link
      if doi.present?
        doi_url
      else
        handle_url
      end
    end

    def handle_url
      if hdl.first.present?
        "http://hdl.handle.net/2027/fulcrum.#{hdl.first}"
      else
        # Right now handles match up with the NOID, but that won't always be true (probably)
        # This works for now, but might need to be removed in the future
        "http://hdl.handle.net/2027/fulcrum.#{id}"
      end
    end

    def doi_url
      doi.first
    end

    def allow_download?
      if allow_download == 'yes' || allow_download.first == 'yes'
        true
      else
        false
      end
    end

    # Google Analytics
    def pageviews
      pageviews_by_path(curation_concerns_file_set_path(id))
    end

    # Technical Metadata
    def width
      solr_document['width_is']
    end

    def height
      solr_document['height_is']
    end

    def mime_type
      solr_document['mime_type_ssi']
    end

    def file_size
      solr_document['file_size_is']
    end

    def last_modified
      solr_document['date_modified_dtsi']
    end

    def original_checksum
      solr_document['original_checksum_ssim']
    end

    def sample_rate
      solr_document['sample_rate_ssim']
    end

    def duration
      solr_document['duration_ssim']
    end

    def original_name
      solr_document['original_name_tesim']
    end
  end
end
