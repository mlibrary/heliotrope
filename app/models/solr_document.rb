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
    date:         'date_created_tesim',
    description:  ['oai_description'],
    # format:       ['file_extent_tesim', 'file_format_tesim'],
    # See HELIO-4143 for definitions of identifiers and relations for IRUS
    identifier:   ['oai_handle', 'oai_doi', 'oai_preferred_isbn', 'identifier_ssim'],
    relation:     ['oai_other_isbns'],
    # language:     'language_label_tesim',
    publisher:    'publisher_tesim', # or press here maybe?
    # rights:       'oai_rights',
    # source:       ['source_tesim', 'isBasedOnUrl_tesim'],
    subject:      ['subject_tesim', 'keyword_tesim'],
    title:        'title_tesim',
    type:         'resource_type_tesim'
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
                         'oai_description'].include?(key)
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

  # Do content negotiation for AF models.
  use_extension(Hydra::ContentNegotiation)

  # Override hyrax
  def itemtype
    return 'http://schema.org/CreativeWork' if resource_type.blank?
    Hyrax::ResourceTypesService.microdata_type(resource_type.first)
  end
end
