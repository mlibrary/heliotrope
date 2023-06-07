# frozen_string_literal: true

class BookSearchHitsController < ApplicationController
  # Get hit counts based on solr highlighting
  # HELIO-4460
  # To be called for each monograph from the monograph_catalog page via javascript
  def hits
    if Rails.env.development?
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET'
      headers['Access-Control-Request-Method'] = '*'
    end

    solr_params = {
      'hl' => true,
      'hl.fl' => 'page_content_tsiv',
      'hl.simple.pre' => '<em>',
      'hl.simple.post' => '</em>',
      'hl.snippets': '50',
      'hl.fragsize': '50',
      'hl.maxAnalyzedChars': '10000',
      df: 'page_content_tsiv',
      qf: "page_content_tsiv",
      fl: ['id'],
      fq: "has_model_ssim:PdfPage AND press_tesim:#{params[:press]} AND file_set_id_ssi:#{params[:file_set_id]}"
    }

    response = ActiveFedora::SolrService.get("page_content_tsiv:#{params[:q]}", solr_params)
    solr_hits = 0
    response["highlighting"].values.map { |r| solr_hits += r["page_content_tsiv"].count }

    render json: { solr_hits: solr_hits }, status: :ok
  end

  private

    def book_search_hits_params
      params.require(:q, :press, :file_set_id).permit(:q, :press, :file_set_id)
    end
end
