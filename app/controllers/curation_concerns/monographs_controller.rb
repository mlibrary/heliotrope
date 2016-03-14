class CurationConcerns::MonographsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Monograph

  self.show_presenter = CurationConcerns::MonographPresenter
end
