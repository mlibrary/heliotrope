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

  def date_published
    fetch('date_published_tesim', [])
  end

  def isbn
    fetch('isbn_tesim', [])
  end

  def editor
    fetch('editor_tesim', [])
  end

  def copyright_holder
    fetch('copyright_holder_tesim', [])
  end

  def buy_url
    fetch('buy_url_ssim', [])
  end

  def caption
    fetch('caption_tesim', [])
  end

  def alt_text
    fetch('alt_text_tesim', [])
  end

  def resource_type
    fetch('resource_type_tesim', [])
  end

  def content_type
    fetch('content_type_tesim', [])
  end

  def keywords
    fetch('keywords_tesim', [])
  end

  def relation
    fetch('relation_tesim', [])
  end

  def identifier
    fetch('identifier_tesim', [])
  end

  def creator_full_name
    fetch('creator_full_name_tesim', [])
  end

  use_extension(Hydra::ContentNegotiation)
end
