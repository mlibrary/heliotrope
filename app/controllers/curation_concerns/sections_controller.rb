# Generated via
#  `rails generate curation_concerns:work Section`

class CurationConcerns::SectionsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Section
  self.show_presenter = CurationConcerns::SectionPresenter
end
