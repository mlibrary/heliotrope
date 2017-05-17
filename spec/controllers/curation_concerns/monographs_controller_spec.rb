# frozen_string_literal: true

require 'rails_helper'

describe CurationConcerns::MonographsController do
  context 'actions' do
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
            get :new, params: { press: subdomain }
            expect(form["press"]).to match(/#{subdomain}/)
          end
        end
      end

      describe "#show" do
        it 'is successful' do
          get :show, params: { id: monograph }
          expect(response).to be_success
        end
      end

      describe "#create" do
        it 'is successful' do
          post :create, params: { monograph: { title: ['Title one'],
                                               press: press.subdomain,
                                               date_published: ['Oct 20th'] } }

          expect(assigns[:curation_concern].title).to eq ['Title one']
          expect(assigns[:curation_concern].date_published).to eq ['Oct 20th']
          expect(assigns[:curation_concern].press).to eq press.subdomain
          expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(assigns[:curation_concern])
        end
      end

      describe "#publish" do
        it 'is successful' do
          expect(PublishJob).to receive(:perform_later).with(monograph)
          post :publish, params: { id: monograph }
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
              post :create, params: { monograph: { title: ['Title one'],
                                                   press: press.subdomain } }
            }.to change { Monograph.count }.by(1)

            expect(assigns[:curation_concern].title).to eq ['Title one']
            expect(assigns[:curation_concern].press).to eq press.subdomain
            expect(response).to redirect_to Rails.application.routes.url_helpers.curation_concerns_monograph_path(assigns[:curation_concern])
          end
        end

        context "within a press that I don't have permission for" do
          it 'denies access' do
            expect {
              post :create, params: { monograph: { title: ['Title one'],
                                                   press: press.subdomain } }
            }.not_to change { Monograph.count }

            expect(response.status).to eq 401
            expect(response).to render_template :unauthorized
          end
        end
      end
    end # press-level admin
  end # actions

  context 'tombstone' do
    let(:user) { create(:platform_admin) }
    let(:press) { create(:press) }
    let(:monograph) { create(:monograph, user: user, press: press.subdomain) }

    before do
      sign_in user
    end

    context 'monograph created' do
      before do
        get :show, params: { id: monograph.id }
      end
      it do
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
        expect(response).to render_template("curation_concerns/monographs/show")
      end
    end

    #
    # Currently returns 404 (:not_found)
    # ActionView::MissingTemplate: Missing template ./public/404.html
    # Since are using jekyll we don't have a 404.html under public
    # But we do have ./public/404/index.html
    # Regardless we are not currently using this controller for Monographs
    # Monographs are shown with the monograph_catalog_controller
    # Hence this test is commented out as a record of history
    #
    # context 'monograph deleted' do
    #   before do
    #     monograph.destroy!
    #     get :show, params: { id: monograph.id }
    #   end
    #   it do
    #     # The HTTP response status code 302 Found is a common way of performing URL redirection.
    #     expect(response).to have_http_status(:found)
    #     # raise CanCan::AccessDenied currently redirects to root_url
    #     expect(response.header["Location"]).to match "http://test.host/"
    #   end
    # end
  end
end
