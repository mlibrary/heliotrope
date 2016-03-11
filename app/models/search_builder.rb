# frozen_string_literal: true
class SearchBuilder < CurationConcerns::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior

  private

    # Exclude Section objects from search results
    def work_types
      CurationConcerns.config.curation_concerns - [Section]
    end
end
