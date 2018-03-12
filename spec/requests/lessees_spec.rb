# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Lessees", type: :request do
  context 'unauthorized' do
    describe "GET /lessees" do
      it "works! (now write some real specs)" do
        get lessees_path
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'authorized' do
    let(:user) { create(:platform_admin) }

    before { cosign_sign_in(user) }

    describe "GET /lessees" do
      it "works! (now write some real specs)" do
        get lessees_path
        expect(response).to have_http_status(200)
      end
    end
  end
end
