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

  describe "#create" do
    it 'is successful' do
      post :create, monograph: { title: ['Title one'],
                                 date_published: ['Oct 20th'] }

      expect(assigns[:curation_concern].title).to eq ['Title one']
      expect(assigns[:curation_concern].date_published).to eq ['Oct 20th']
      expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(assigns[:curation_concern])
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
