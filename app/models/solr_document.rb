# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include BlacklightOaiProvider::SolrDocument

  # Adds Hyrax behaviors to the SolrDocument.
  include Hyrax::SolrDocumentBehavior

  include SolrDocumentExtensions
  include HeliotropeMimeTypes
  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

  # I think these are all secific DC fields...
  field_semantics.merge!(
    contributor:  ['contributor_tesim'],
    coverage:     ['location_tesim'],
    creator:      ['creator_tesim'],
    date:         'oai_date',
    description:  ['oai_description'],
    # format:       ['file_extent_tesim', 'file_format_tesim'],
    # See HELIO-4143 for definitions of identifiers and relations for IRUS
    identifier:   ['oai_handle', 'oai_doi', 'oai_preferred_isbn', 'identifier_ssim'],
    relation:     ['oai_relations'],
    # language:     'language_label_tesim',
    publisher:    'publisher_tesim', # or press here maybe?
    rights:       'oai_rights',
    # source:       ['source_tesim', 'isBasedOnUrl_tesim'],
    subject:      ['subject_tesim', 'keyword_tesim'],
    title:        'title_tesim',
    type:         'oai_type'
  )

  def sets
    OaiPressSet.sets_for(self)
  end

  # Override SolrDocument hash access for certain virtual fields
  def [](key)
    return send(key) if ['oai_identifier',
                         'oai_handle',
                         'oai_doi',
                         'oai_preferred_isbn',
                         'oai_other_isbns',
                         'oai_description',
                         'oai_rights',
                         'oai_relations',
                         'oai_date',
                         'oai_type'].include?(key)
    super
  end

  # If there's a handle in the fedora handle field, use that (919 heb titles have this)
  # If there's a handle in the identifier field (a lot of heb has this), then do nothing since we're already adding identifier_ssim
  # Otherwise, all objects have a default fulcrum handle registered, use that
  def oai_handle
    return "https://hdl.handle.net/" + self['hdl_ssim'].first if self['hdl_ssim'].present?
    return if self['identifier_ssim'].present? && self['identifier_ssim'].find { |e| /2027\/heb\./i =~ e }.present?
    "https://hdl.handle.net/" + "2027/fulcrum." + id
  end

  def oai_preferred_isbn
    Sighrax.from_solr_document(self).preferred_isbn.presence
  end

  def oai_other_isbns
    Sighrax.from_solr_document(self).non_preferred_isbns.presence
  end

  def oai_doi
    "https://doi.org/" + self['doi_ssim']&.first if self['doi_ssim'].present?
  end

  def oai_description
    # get rid of the markdown
    MarkdownService.markdown_as_text(self["description_tesim"].first) if self["description_tesim"].present?
  end

  def oai_rights
    rights = []
    rights << if oai_open_access?
                'info:eu-repo/semantics/openAccess'
              else
                'info:eu-repo/semantics/restrictedAccess'
              end
    rights << oai_cc_license if oai_open_access? && oai_cc_license.present?
    rights.uniq
  end

  def oai_relations
    (Array(oai_other_isbns) + oai_alt_identifier_relations).map(&:to_s).map(&:strip).reject(&:blank?).uniq
  end

  def oai_date
    oai_normalized_date(Array(self['date_published_dtsim']).first).presence ||
      Array(self['date_created_tesim']).first.to_s.strip.presence ||
      oai_normalized_date(Array(self['date_uploaded_dtsi']).first).presence
  end

  def oai_type
    (['info:eu-repo/semantics/book'] + Array(self['resource_type_tesim'])).map(&:to_s).map(&:strip).reject(&:blank?).uniq
  end

  # Do content negotiation for AF models.
  use_extension(Hydra::ContentNegotiation)

  # Override hyrax
  def itemtype
    return 'http://schema.org/CreativeWork' if resource_type.blank?
    Hyrax::ResourceTypesService.microdata_type(resource_type.first)
  end

  private

    def oai_open_access?
      open_access&.casecmp('yes')&.zero? || false
    end

    def oai_cc_license
      Array(self['license_tesim']).first.to_s.strip.presence
    end

    def oai_alt_identifier_relations
      relations = []

      handle = oai_identifier_without_url_prefix(oai_handle, %r{\Ahttps?://hdl\.handle\.net/}i)
      relations << "info:eu-repo/semantics/altIdentifier/hdl/#{handle}" if handle.present?

      doi = oai_identifier_without_url_prefix(oai_doi, %r{\Ahttps?://doi\.org/}i)
      relations << "info:eu-repo/semantics/altIdentifier/doi/#{doi}" if doi.present?

      oai_isbn_identifiers.each do |isbn|
        relations << "info:eu-repo/semantics/altIdentifier/isbn/#{isbn}"
      end

      relations
    end

    def oai_isbn_identifiers
      ([oai_preferred_isbn] + Array(oai_other_isbns)).map { |isbn| isbn.to_s.gsub(/\s+/, '') }.reject(&:blank?).uniq
    end

    def oai_identifier_without_url_prefix(value, prefix_pattern)
      value.to_s.sub(prefix_pattern, '').strip.presence
    end

    def oai_normalized_date(value)
      return if value.blank?
      return value.to_date.to_s if value.respond_to?(:to_date)
      Time.zone.parse(value.to_s)&.to_date&.to_s
    end
end
