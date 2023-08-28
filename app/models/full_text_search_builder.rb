# frozen_string_literal: true

# TODO: give this a better name that indicates it's full text hits within discrete 'pages' of text only
class FullTextSearchBuilder < Blacklight::SearchBuilder
  self.default_processor_chain += [
    :filter_by_monograph_id
  ]

  def filter_by_monograph_id(solr_parameters)
    id = monograph_id(blacklight_params)
    solr_parameters[:qt] = 'search'
    solr_parameters[:sort] = 'page_number_isi asc'
    solr_parameters[:rows] = '1000'
    solr_parameters[:fq] ||= []
    # with this naming scheme if we fly with this solution there will be...
    # `(has_model_ssim:PdfPage OR has_model_ssim:EpubParagraph)` here one day. Or something like that.
    solr_parameters[:fq] << "has_model_ssim:PdfPage AND monograph_id_ssi:#{id} AND page_content_tesiv:#{blacklight_params[:q]}"

    solr_parameters[:fl] = ['id']
    solr_parameters[:qf] ||= []
    solr_parameters[:qf] << 'page_content_tesiv'
    solr_parameters[:df] ||= []
    solr_parameters[:df] << 'page_content_tesiv'

    # This is a difference to the Press catalog "all text in one field" full text search that gets Monographs into...
    # the listing in the first place. Means "minimum match" of 1 "clause", like a logical OR essentially.
    # Because multiple "clauses" that were found across the whole book might not both be on any page in that book.
    # But we still want to show any and all relevant snippets underneath that result. See:
    # https://solr.apache.org/guide/6_6/the-dismax-query-parser.html#TheDisMaxQueryParser-Themm_MinimumShouldMatch_Parameter
    solr_parameters[:mm] = '1'

    solr_parameters[:hl] = 'true'
    solr_parameters['hl.q'.to_sym] = "page_content_tesiv:#{blacklight_params[:q]}"

    solr_parameters["hl.method".to_sym] = 'unified'
    solr_parameters["hl.tag.pre".to_sym] = '<b><em>'
    solr_parameters["hl.tag.post".to_sym] = '</b></em>'
    solr_parameters["hl.snippets".to_sym] = '100'
    solr_parameters["hl.fragsize".to_sym] = '100'
    solr_parameters["hl.maxAnalyzedChars".to_sym] = '10000'
  end

  private

    def monograph_id(blacklight_params)
      blacklight_params[:monograph_id] || blacklight_params['id']
    end
end
