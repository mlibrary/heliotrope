# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PressesController, type: :controller do
  describe "#index" do
    context "as a signed in user" do
      let(:user) { create(:user) }
      let!(:press) { create(:press) }

      before { sign_in user }

      it 'shows the presses' do
        get :index
        expect(response).to be_success
        expect(assigns[:presses]).to include press
      end
    end
  end
end
