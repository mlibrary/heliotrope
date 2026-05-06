# frozen_string_literal: true

class PdfAccessibilityMetadataPresenter
  def initialize(solr_document)
    @solr_document = solr_document
  end

  def a11y_format
    @solr_document['reader_ebook_format_sim'] || 'PDF'
  end

  def a11y_screen_reader_friendly
    value = @solr_document['pdf_a11y_screen_reader_friendly_ssi']
    value.presence || 'No information is available'
  end

  def a11y_accessibility_summary
    nil
  end

  def a11y_conforms_to
    @solr_document['pdf_a11y_conforms_to_ssi'].presence
  end

  def a11y_certified_by
    nil
  end

  def a11y_certifier_credential
    nil
  end

  def a11y_accessibility_hazards
    nil
  end

  def a11y_accessibility_features
    @a11y_accessibility_features ||= @solr_document['pdf_a11y_accessibility_feature_ssim']&.uniq
  end

  def a11y_access_modes
    @solr_document['pdf_a11y_access_mode_ssim']
  end

  def a11y_access_modes_sufficient
    nil
  end



  def prepopulated_link_for_accessible_copy_request_form
    return @prepopulated_link_for_accessible_copy_request_form if @prepopulated_link_for_accessible_copy_request_form.present?

    link = "https://umich.qualtrics.com/jfe/form/SV_8AiVezqglaUnQZo?noid=#{@solr_document.id}"
    link += "&press=#{@solr_document['press_tesim'].first}" if @solr_document['press_tesim']&.first&.present?

    populate_params = []
    populate_params << "%22QID3%22:%22#{CGI.escape(MarkdownService.markdown_as_text(@solr_document.title&.first))}%22" if @solr_document.title&.first.present?
    populate_params << "%22QID4%22:%22#{CGI.escape(@solr_document.creator_full_name)}%22" if @solr_document&.creator_full_name.present?
    populate_params << "%22QID5%22:%22#{CGI.escape(@solr_document.isbn.first)}%22" if @solr_document.isbn&.first.present?
    populate_params << "%22QID14%22:%22#{CGI.escape(@solr_document.publisher.first)}%22" if @solr_document.publisher&.first.present?

    link += "&Q_PopulateResponse={#{populate_params.join(',')}}" if populate_params.present?

    @prepopulated_link_for_accessible_copy_request_form = link
  end
end
