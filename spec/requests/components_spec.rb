# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Components", type: :request do
  context 'unauthorized' do
    describe "GET /components" do
      it do
        get components_path
        expect(response).to have_http_status(302)
        expect(response).to redirect_to(presses_path)
      end
    end
  end

  context 'authorized' do
    let(:user) { create(:platform_admin) }

    before { cosign_sign_in(user) }

    describe "GET /components" do
      it do
        get components_path
        expect(response).to have_http_status(200)
      end
    end
  end
end
