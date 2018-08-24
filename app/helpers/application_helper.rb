# frozen_string_literal: true

module ApplicationHelper
  delegate :current_institutions?, :current_institutions, to: :controller

  # Heliotrope override of Blacklight::BlacklightHelperBehavior
  ##
  # Get the current "view type" (and ensure it is a valid type)
  #
  # @param [Hash] query_params the query parameters to check
  # @return [Symbol]
  def document_index_view_type(query_params = params)
    # The press catalog will *always* be gallery
    return "gallery" if controller_name == "press_catalog"
    view_param = query_params[:view]
    view_param ||= session[:preferred_view]
    if view_param && document_index_views.key?(view_param.to_sym)
      view_param.to_sym
    else
      default_document_index_view_type
    end
  end
end
