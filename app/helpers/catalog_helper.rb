# frozen_string_literal: true

module CatalogHelper
  include Blacklight::CatalogHelperBehavior

  ##
  # Look up the current sort field, or provide the default if none is set
  #
  # @return [Blacklight::Configuration::SortField]
  def current_sort_field # rubocop:disable Metrics/CyclomaticComplexity
    csf = (blacklight_config.sort_fields.values.find { |f| f.sort == @response.sort } if @response&.sort.present?) || blacklight_config.sort_fields[params[:sort]] || default_sort_field # rubocop:disable Rails/HelperInstanceVariable
    return csf unless default_sort_field&.key == 'relevance' # First field in the sort fields list when searching
    return blacklight_config.sort_fields[params[:sort]] if blacklight_config.sort_fields[params[:sort]].present?
    default_sort_field                                       # NOTE: Not the same thing as blacklight_config.default_sort_field which is used when browsing
  end
end
