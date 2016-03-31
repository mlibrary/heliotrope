# frozen_string_literal: true
class SearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  include Hydra::AccessControlsEnforcement
  include CurationConcerns::SearchFilters

  private

    # Exclude Section objects from search results
    def work_types
      CurationConcerns.config.curation_concerns - [Section]
    end
end
