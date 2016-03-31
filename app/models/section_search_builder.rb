class SectionSearchBuilder < ::SearchBuilder
  private

    def work_types
      CurationConcerns.config.curation_concerns
    end
end
