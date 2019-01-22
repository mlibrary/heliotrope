# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::MonographsController, type: :controller do
  context 'actions' do
    let(:monograph) { create(:monograph, user: user, press: press.subdomain) }
    let(:press) { build(:press) }
    let!(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
    end

    before do
      sign_in user
      stub_out_redis
    end

    context 'a platform admin' do
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
          post :create, params: { monograph: { title: 'Title one',
                                               press: press.subdomain,
                                               date_created: '2001' } }

          expect(assigns[:curation_concern].title).to eq ['Title one']
          expect(assigns[:curation_concern].date_created).to eq ['2001']
          expect(assigns[:curation_concern].press).to eq press.subdomain
          expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(assigns[:curation_concern], locale: I18n.locale)
        end
      end

      describe "#publish" do
        it 'is successful' do
          expect(PublishJob).to receive(:perform_later).with(monograph)
          post :publish, params: { id: monograph }
          expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(monograph, locale: I18n.locale)
          expect(flash[:notice]).to eq "Monograph is publishing."
        end
      end

      describe "reindex" do
        it 'is successful' do
          expect(CurationConcernUpdateIndexJob).to receive(:perform_later).with(monograph)
          patch :reindex, params: { id: monograph }
          expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(monograph, locale: I18n.locale)
          expect(flash[:notice]).to eq I18n.t('monograph_catalog.index.reindexing', title: monograph.title&.first)
        end
      end
    end # platform admin

    context 'a press-level admin' do
      let(:user) { create(:press_admin) }

      describe "#create" do
        context 'within my own press' do
          let(:press) { user.presses.first }

          it 'is successful' do
            expect {
              post :create, params: { monograph: { title: 'Title one',
                                                   press: press.subdomain } }
            }.to change(Monograph, :count).by(1)

            expect(assigns[:curation_concern].title).to eq ['Title one']
            expect(assigns[:curation_concern].press).to eq press.subdomain
            expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(assigns[:curation_concern], locale: I18n.locale)
          end
        end

        context "within a press that I don't have permission for" do
          it 'denies access' do
            expect {
              post :create, params: { monograph: { title: ['Title one'],
                                                   press: press.subdomain } }
            }.not_to change(Monograph, :count)

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
        expect(response).to render_template("hyrax/monographs/show")
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

  context 'anonymous user' do
    let(:press) { create(:press) }
    let(:user) { create(:user) }
    let(:monograph) { create(:monograph, user: user, press: press.subdomain) }

    describe "#show" do
      it 'is redirected' do
        get :show, params: { id: monograph }
        expect(response).to redirect_to Rails.application.routes.url_helpers.hyrax_monograph_path(monograph, locale: I18n.locale)
      end
    end
  end
end
