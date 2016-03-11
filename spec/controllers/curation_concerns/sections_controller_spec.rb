require 'rails_helper'

describe CurationConcerns::SectionsController do
  describe "#show_presenter" do
    subject { controller.show_presenter }
    it { is_expected.to eq CurationConcerns::SectionPresenter }
  end
end
