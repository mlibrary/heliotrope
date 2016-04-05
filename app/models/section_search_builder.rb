class SectionSearchBuilder < ::SearchBuilder
  include CurationConcerns::SingleResult

  private

    def work_types
      CurationConcerns.config.curation_concerns
    end
end
