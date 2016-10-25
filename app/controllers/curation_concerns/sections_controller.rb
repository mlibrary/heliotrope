class CurationConcerns::SectionsController < ApplicationController
  include CurationConcerns::CurationConcernController
  self.curation_concern_type = Section
  self.show_presenter = CurationConcerns::SectionPresenter

  def search_builder_class
    ::SectionSearchBuilder
  end

  def update
    # If a section's title is changed, we need to re-index all of it's file_sets
    # in order for the section facet on the monograph_catalog page to work right
    # see #542
    if curation_concern.title != params[:section][:title]
      curation_concern.members.each do |member|
        ReindexFileSetJob.perform_later(member) if member.file_set?
      end
    end
    super
  end
end
