class CurationConcerns::SectionsController < ApplicationController
  include CurationConcerns::CurationConcernController
  self.curation_concern_type = Section
  self.show_presenter = CurationConcerns::SectionPresenter

  def search_builder_class
    ::SectionSearchBuilder
  end
end
