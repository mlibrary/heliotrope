# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Score`
require 'rails_helper'

RSpec.describe Hyrax::ScoresController do
  describe "#new" do
    context "a score_press admin" do
      let(:press) { create(:press, subdomain: Services.score_press) }
      let(:admin) { create(:press_admin, press: press) }
      let(:form) { assigns(:form) }

      before do
        sign_in admin
      end

      it "is successful" do
        get :new
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:new)
        expect(form["press"]).to match(/#{Services.score_press}/)
      end
    end

    context "a press_admin for a different press" do
      let(:press) { create(:press) }
      let(:admin) { create(:press_admin, press: press) }

      before do
        sign_in admin
      end

      it "unauthorized: redirects to /" do
        # This will probably change in the future. Being unauthorized should probably
        # be explicitly shown a 401. We have a ticket to do that work: HELIO-2904
        get :new
        expect(response).not_to be_success
        expect(response).to redirect_to(Rails.application.routes.url_helpers.root_path(locale: I18n.locale))
      end
    end
  end

  describe "#create" do
    context "a score_press admin" do
      let(:press) { create(:press, subdomain: Services.score_press) }
      let(:admin) { create(:press_admin, press: press) }

      before do
        sign_in admin
        stub_out_redis
      end

      it 'is successful' do
        post :create, params: { score: { title: 'Title one' } }

        expect(assigns[:curation_concern].title).to eq ['Title one']
        expect(assigns[:curation_concern].press).to eq Services.score_press
        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_score_path(assigns[:curation_concern], locale: I18n.locale)
      end
    end

    context "a press_admin from a different press" do
      let(:press) { create(:press) }
      let(:admin) { create(:press_admin, press: press) }

      before do
        sign_in admin
        stub_out_redis
      end

      it 'denies access' do
        post :create, params: { score: { title: 'Title one' } }

        expect(response.status).to eq 401
        expect(response).to render_template :unauthorized
      end
    end
  end

  describe "#show" do
    # only admin/editors should be able to see the hyrax show page, not normal users
    context 'anonymous user' do
      let(:press) { create(:press, subdomain: Services.score_press) }
      let(:admin) { create(:press_admin, press: press) }
      let(:score) { create(:public_score, user: admin, press: press.subdomain) }

      it 'is redirected' do
        get :show, params: { id: score }
        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_score_path(score, locale: I18n.locale)
      end
    end

    context "any kind of privileged user" do
      let(:press) { create(:press, subdomain: Services.score_press) }
      let(:admin) { create(:press_admin, press: press) }
      let(:score) { create(:public_score, user: admin, press: press.subdomain) }

      it "succeeds" do
        sign_in admin
        get :show, params: { id: score }

        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("hyrax/scores/show")
      end
    end
  end
end
