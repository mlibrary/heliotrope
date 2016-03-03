require 'rails_helper'

describe CurationConcerns::MonographsController do
  let(:monograph) { create(:monograph, user: user) }
  let(:user) { create(:user) }

  describe "#show" do
    before do
      sign_in user
    end

    it 'is successful' do
      get :show, id: monograph
      expect(response).to be_success
    end
  end
end
