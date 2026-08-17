# frozen_string_literal: true

# Search builder for the full-catalog endpoints (CatalogController and its
# subclass AdminCatalogController).
#
# The default Hyrax::FilterByType behavior (mixed in via Hyrax::SearchFilters ->
# ::SearchBuilder) limits results to work + collection models, which excludes
# FileSets. For the full catalog we want the default, unfiltered results to
# contain Monographs (from all presses) *and* FileSets, so we override #models
# to add FileSet and drop collections.
class CatalogSearchBuilder < ::SearchBuilder
  self.default_processor_chain += [
    :filter_published_monographs_for_oai
  ]

  # Include FileSets alongside the registered work types (Monograph), and omit
  # collection classes.
  def models
    work_classes + [::FileSet]
  end

  def filter_published_monographs_for_oai(solr_parameters)
    oai_verbs = %w[ListRecords ListIdentifiers]
    return unless oai_verbs.include?(blacklight_params[:verb].to_s)

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '{!terms f=has_model_ssim}Monograph'
    solr_parameters[:fq] << 'visibility_ssi:open'
    solr_parameters[:fq] << '-suppressed_bsi:true'
  end
end
