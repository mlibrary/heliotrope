# frozen_string_literal: true

require 'rails_helper'

describe CurationConcerns::MonographsController do
  let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
  let(:press) { build(:press) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  before do
    sign_in user
  end

  context 'a platform superadmin' do
    let(:user) { create(:platform_admin) }

    describe "#new" do
      context 'press parameter' do
        let(:subdomain) { "subdomain" }
        let(:form) { assigns(:form) }
        it 'handles missing press param' do
          get :new
          expect(form["press"]).to match(//)
        end
        it 'handles press param' do
          get :new, press: subdomain
          expect(form["press"]).to match(/#{subdomain}/)
        end
      end
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
                                   press: press.subdomain,
                                   date_published: ['Oct 20th'] }

        expect(assigns[:curation_concern].title).to eq ['Title one']
        expect(assigns[:curation_concern].date_published).to eq ['Oct 20th']
        expect(assigns[:curation_concern].press).to eq press.subdomain
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
  end # platform superadmin

  context 'a press-level admin' do
    let(:user) { create(:press_admin) }

    describe "#create" do
      context 'within my own press' do
        let(:press) { user.presses.first }

        it 'is successful' do
          expect {
            post :create, monograph: { title: ['Title one'],
                                       press: press.subdomain }
          }.to change { Monograph.count }.by(1)

          expect(assigns[:curation_concern].title).to eq ['Title one']
          expect(assigns[:curation_concern].press).to eq press.subdomain
          expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(assigns[:curation_concern])
        end
      end

      context "within a press that I don't have permission for" do
        it 'denies access' do
          expect {
            post :create, monograph: { title: ['Title one'],
                                       press: press.subdomain }
          }.not_to change { Monograph.count }

          expect(response.status).to eq 401
          expect(response).to render_template :unauthorized
        end
      end
    end
  end # press-level admin
end
