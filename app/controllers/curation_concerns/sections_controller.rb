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
    if params[:section][:title] && curation_concern.title != params[:section][:title]
      curation_concern.members.each do |member|
        ReindexFileSetJob.perform_later(member) if member.file_set?
      end
    end

    super

    # Reindex this section's monograph. Note that this section gets reindexed here anyway...
    # which is crucial for setting the monograph's Solr doc's ordered_fileset_ids
    if params[:section][:ordered_member_ids]
      Monograph.find(curation_concern.monograph_id).update_index
    end
  end
end
