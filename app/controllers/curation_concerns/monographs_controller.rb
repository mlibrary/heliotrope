class CurationConcerns::MonographsController < ApplicationController
  include CurationConcerns::CurationConcernController
  set_curation_concern_type Monograph

  self.show_presenter = CurationConcerns::MonographPresenter

  def publish
    PublishJob.perform_later(curation_concern)
    redirect_to [main_app, curation_concern], notice: 'Monograph is publishing.'
  end
end
