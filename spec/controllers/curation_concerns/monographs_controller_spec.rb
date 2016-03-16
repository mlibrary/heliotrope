require 'rails_helper'

describe CurationConcerns::MonographsController do
  let(:monograph) { create(:monograph, user: user) }
  let(:user) { create(:user) }
  before do
    sign_in user
  end

  describe "#show" do
    it 'is successful' do
      get :show, id: monograph
      expect(response).to be_success
    end
  end

  describe "#publish" do
    it 'is successful' do
      expect(PublishJob).to receive(:perform_later).with(monograph)
      post :publish, id: monograph
      expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(monograph)
      expect(flash[:notice]).to eq "Monograph is publishing."
    end
  end
end
