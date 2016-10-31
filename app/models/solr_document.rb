# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document
  # Adds CurationConcerns behaviors to the SolrDocument.
  include CurationConcerns::SolrDocumentBehavior

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

  # Do content negotiation for AF models.

  ssim_fields = [
    'allow_display_after_expiration',
    'allow_download',
    'allow_download_after_expiration',
    'allow_hi_res',
    'book_needs_handles',
    'buy_url',
    'copyright_status',
    'credit_line',
    'exclusive_to_platform',
    'external_resource',
    'ext_url_doi_or_handle',
    'doi',
    'hdl',
    'holding_contact',
    'permissions_expiration_date',
    'rights_granted',
    'rights_granted_creative_commons',
    'section_id',
    'use_crossref_xml'
  ]

  ssim_fields.each do |field|
    define_method(field) do
      fetch("#{field}_ssim", [])
    end
  end

  tesim_fields = [
    'alt_text',
    'caption',
    'content_type',
    'copyright_holder',
    'creator_family_name',
    'creator_full_name',
    'creator_given_name',
    'date_published',
    'display_date',
    'editor',
    'identifier',
    'isbn',
    'isbn_paper',
    'isbn_ebook',
    'keywords',
    'primary_creator_role',
    'relation',
    'resource_type',
    'section_title',
    'sort_date',
    'search_year',
    'transcript',
    'translation'
  ]

  tesim_fields.each do |field|
    define_method(field) do
      fetch("#{field}_tesim", [])
    end
  end

  use_extension(Hydra::ContentNegotiation)
end
