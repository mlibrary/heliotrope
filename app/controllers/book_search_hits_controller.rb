# frozen_string_literal: true

class BookSearchHitsController < ApplicationController
  # Get hit counts based on solr highlighting
  # HELIO-4460
  # To be called for each monograph from the monograph_catalog page via javascript
  def hits
    return unless Flipflop.search_snippets?

    if Rails.env.development?
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'GET'
      headers['Access-Control-Request-Method'] = '*'
    end

    # Some of these keys do not work as symbols, and with_indifferent_access() doesn't help either. Stick with strings.
    solr_params = {
      'qt' => 'search', # this has to be `search` to exactly match the hits from Blacklight (PressSearchBuilder, PressCatalogController)
      'hl' => true,
      'hl.fl' => 'page_content_tesiv',
      'hl.simple.pre' => '<b><em>',
      'hl.simple.post' => '</em></b>',
      'hl.snippets' => '1',
      'hl.fragsize' => '200',
      'hl.maxAnalyzedChars' => '10000',
      'df' => 'page_content_tesiv',
      'qf' => "page_content_tesiv",
      # This is a difference to the Press catalog "all text in one field" full text search that gets Monographs into...
      # the listing in the first place. Means "minimum match" of 1 "clause", like a logical OR essentially.
      # Because multiple "clauses" that were found across the whole book might not both be on any page in that book.
      # But we still want to show any and all relevant snippets underneath that result. See:
      # https://solr.apache.org/guide/6_6/the-dismax-query-parser.html#TheDisMaxQueryParser-Themm_MinimumShouldMatch_Parameter
      'mm' => '1',
      'fl' => ['id'],
      'fq' => "has_model_ssim:PdfPage AND file_set_id_ssi:#{params[:file_set_id]}",
      'rows' => 1
    }

    response = ActiveFedora::SolrService.get("page_content_tesiv:#{params[:q]}", solr_params)

    page_number, highlight = nil
    solr_hits = response['response']['numFound']

    if solr_hits > 0
      page_id = response['response']['docs'].first['id']
      page_number = page_id.split('_')[1]
      highlight = response["highlighting"].dig(page_id, 'page_content_tesiv').first
    end

    render json: { solr_hits: solr_hits,
                   page_number: page_number,
                   highlight: highlight }, status: :ok
  end

  private

    def book_search_hits_params
      params.require(:q, :file_set_id).permit(:q, :file_set_id)
    end
end
