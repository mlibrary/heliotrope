# frozen_string_literal: true

class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include Hyrax::SearchFilters

  def sort
    sort_field = if blacklight_params[:sort].blank?
                   # no sort param provided, use default
                   default_sort_field
                 else
                   # check for sort field key
                   blacklight_config.sort_fields[blacklight_params[:sort]]
                 end

    field = if sort_field.present?
              sort_field.sort
            else
              # just pass the key through
              blacklight_params[:sort]
            end

    field.presence
  end

  def default_sort_field # rubocop:disable Rails/Delegate
    blacklight_config.default_sort_field
  end
end
