# frozen_string_literal: true

class BookSearchHitsController < ApplicationController
  def hits
    return head :not_found unless Flipflop.search_snippets?
    return head :bad_request unless params[:q].is_a?(String) && params[:q].present?
    return head :not_found unless params[:file_set_id].is_a?(String) && ValidationService.valid_noid?(params[:file_set_id])

    ebook = Sighrax.from_noid(params[:file_set_id])
    return head :not_found unless previewable?(ebook)

    response = ActiveFedora::SolrService.instance.conn.get('select', params: snippet_parameters(ebook.noid).merge('q' => params[:q]))
    snippets = response['response']['docs'].filter_map do |document|
      highlight = response['highlighting'].dig(document['id'], 'page_content_tesiv')&.first
      next if highlight.blank?
      highlight = highlight.gsub(/[[:cntrl:]]/, ' ').squish

      { page_number: document['page_number_isi'],
        highlight: ERB::Util.html_escape(highlight).gsub('[FULCRUM_MATCH_START]', '<mark>').gsub('[FULCRUM_MATCH_END]', '</mark>') }
    end
    render json: { snippets: snippets }
  end

  private

    def previewable?(ebook)
      return false unless ebook.is_a?(Sighrax::PdfEbook)
      monograph = ebook.monograph
      return false unless monograph.is_a?(Sighrax::Monograph)
      return false unless monograph.publisher.press&.subdomain == 'barpublishing'
      return false unless monograph.ebook == ebook

      ebook.published? && monograph.published? && !monograph.tombstone?
    end

    def snippet_parameters(file_set_id)
      {
        'qt' => 'search',
        'defType' => 'edismax',
        'hl' => true,
        'hl.fl' => 'page_content_tesiv',
        'hl.simple.pre' => '[FULCRUM_MATCH_START]',
        'hl.simple.post' => '[FULCRUM_MATCH_END]',
        'hl.snippets' => '1',
        'hl.fragsize' => '180',
        'hl.maxAnalyzedChars' => '-1',
        'df' => 'page_content_tesiv',
        'qf' => 'page_content_tesiv',
        # Query terms can occur on different pages of a book; samples may match any term.
        'mm' => '1',
        'fl' => ['id', 'page_number_isi'],
        'fq' => "has_model_ssim:PdfPage AND file_set_id_ssi:#{file_set_id}",
        'rows' => 3
      }
    end
end
