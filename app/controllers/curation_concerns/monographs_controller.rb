class CurationConcerns::MonographsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Monograph
  # Use the Monograph Presenter
  def show_presenter
    CurationConcerns::MonographPresenter
  end

  self.show_presenter = CurationConcerns::MonographPresenter
end
