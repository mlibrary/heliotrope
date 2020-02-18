# frozen_string_literal: true

module HyraxHelper
  include ::BlacklightHelper
  include Hyrax::BlacklightOverride
  include Hyrax::HyraxHelperBehavior

  # Get the default index view type
  #
  # @return [Symbol]
  def default_document_index_view_type
    controller.is_a?(PressCatalogController) ? :gallery : :list
  end

  # Get the current "view type" (and ensure it is a valid type)
  #
  # @param [Hash] query_params the query parameters to check
  # @return [Symbol]
  def document_index_view_type(query_params = params) # rubocop:disable Metrics/PerceivedComplexity
    view_param = query_params[:view]
    view_param ||= if controller.is_a?(PressCatalogController)
                     session[:preferred_press_view]
                   elsif controller.is_a?(MonographCatalogController)
                     session[:preferred_monograph_view]
                   elsif controller.is_a?(ScoreCatalogController)
                     session[:preferred_score_view]
                   else
                     session[:preferred_view]
                   end
    if view_param && document_index_views.keys.include?(view_param.to_sym)
      view_param.to_sym
    else
      default_document_index_view_type
    end
  end
end
