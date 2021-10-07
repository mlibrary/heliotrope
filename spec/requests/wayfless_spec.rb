# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "(Where Are You From)less", type: :request do
  let (:locale) { { locale: 'en' } }
  let(:anything) { locale.merge({ anything: 'wayfless' }) }
  # let(:entity_id) { { entityID: 'https://shibboleth.umich.edu/idp/shibboleth' } }
  let(:entity_id) { { entityID: 'https://registry.shibboleth.ox.ac.uk/idp' } }

  context 'Press Catalog Index' do
    subject { get press_catalog_path(press.subdomain), params: params }

    let(:press) { create(:press) }
    let(:params) { anything }

    it do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
    end

    context 'when entityID param' do
      let(:params) { anything.merge(entity_id) }

      it do
        subject
        expect(response).to redirect_to(shib_login_path(press_catalog_path(press.subdomain), params: entity_id))
      end

      context 'already logged in by entityID' do
        let(:current_user) { create(:user, request_attributes: request_attributes) }
        let(:request_attributes) { { identity_provider: params[:entityID] } }

        before { sign_in(current_user) }

        it do
          subject
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:index)
        end
      end

      context 'already logged in by other entityID' do
        let(:current_user) { create(:user, request_attributes: request_attributes) }
        let(:request_attributes) { { identity_provider: 'other_entity_id' } }

        before { sign_in(current_user) }

        it do
          subject
          expect(response).to redirect_to(shib_login_path(press_catalog_path(press.subdomain), params: entity_id))
        end
      end
    end
  end

  context 'Monograph Catalog Index' do
    subject { get monograph_catalog_path(monograph.id), params: params }

    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:press) { create(:press) }
    let(:cover) { create(:public_file_set) }
    let(:epub) { create(:public_file_set) }
    let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:params) { anything }

    before do
      monograph.ordered_members << cover
      monograph.representative_id = cover.id
      monograph.ordered_members << epub
      monograph.save!
      cover.save!
      epub.save!
      fr
    end

    it do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:index)
      expect(response.body).not_to match(/You do not have access to this book/)
    end

    context 'when entityID param' do
      let(:params) { anything.merge(entity_id) }

      it do
        subject
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:index)
        expect(response.body).not_to match(/You do not have access to this book/)
      end

      context 'restricted' do
        let(:product) { create(:product, identifier: 'product') }
        let(:component) { create(:component, noid: monograph.id) }

        before { product.components << component }

        it do
          subject
          expect(response).to redirect_to(shib_login_path(monograph_catalog_path(monograph.id), params: entity_id))
        end

        context 'open access' do
          before do
            monograph.open_access = 'yes'
            monograph.save!
          end

          it do
            subject
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:index)
            expect(response.body).not_to match(/You do not have access to this book/)
          end
        end

        context 'already logged in by entityID' do
          let(:current_user) { create(:user, request_attributes: request_attributes) }
          let(:request_attributes) { { identity_provider: params[:entityID] } }

          before { sign_in(current_user) }

          it do
            subject
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:index)
            expect(response.body).to match(/You do not have access to this book/)
          end
        end

        context 'already logged in by other entityID' do
          let(:current_user) { create(:user, request_attributes: request_attributes) }
          let(:request_attributes) { { identity_provider: 'other_entity_id' } }

          before { sign_in(current_user) }

          it do
            subject
            expect(response).to redirect_to(shib_login_path(monograph_catalog_path(monograph.id), params: entity_id))
          end
        end
      end
    end
  end

  context 'FileSet Show' do
    subject { get main_app.hyrax_file_set_path(resource.id), params: params }

    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:press) { create(:press) }
    let(:cover) { create(:public_file_set) }
    let(:resource) { create(:public_file_set) }
    let(:epub) { create(:public_file_set) }
    let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:params) { anything }

    before do
      monograph.ordered_members << cover
      monograph.representative_id = cover.id
      monograph.ordered_members << resource
      monograph.ordered_members << epub
      monograph.save!
      cover.save!
      resource.save!
      epub.save!
      fr
    end

    it do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context 'when entityID param' do
      let(:params) { anything.merge(entity_id) }

      it do
        subject
        expect(response).to redirect_to(main_app.shib_login_path(main_app.hyrax_file_set_path(resource.id), params: entity_id))
      end

      context 'open access' do
        before do
          monograph.open_access = 'yes'
          monograph.save!
        end

        it do
          subject
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context 'already logged in by entityID' do
        let(:current_user) { create(:user, request_attributes: request_attributes) }
        let(:request_attributes) { { identity_provider: params[:entityID] } }

        before { sign_in(current_user) }

        it do
          subject
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
        end
      end

      context 'already logged in by other entityID' do
        let(:current_user) { create(:user, request_attributes: request_attributes) }
        let(:request_attributes) { { identity_provider: 'other_entity_id' } }

        before { sign_in(current_user) }

        it do
          subject
          expect(response).to redirect_to(main_app.shib_login_path(main_app.hyrax_file_set_path(resource.id), params: entity_id))
        end
      end
    end
  end

  context 'Counter Reports Index' do
    subject { get counter_reports_path, params: params }

    let(:params) { anything }

    it do
      subject
      expect(response).to have_http_status(:unauthorized)
      expect(response).to render_template('counter_reports/unauthorized')
    end

    context 'when entityID param' do
      let(:params) { anything.merge(entity_id) }

      it do
        subject
        expect(response).to redirect_to(shib_login_path(counter_reports_path, params: entity_id))
      end

      context 'already logged in by entityID' do
       let(:current_user) { create(:user, request_attributes: request_attributes) }
       let(:request_attributes) { { identity_provider: params[:entityID] } }

       before { sign_in(current_user) }

       it do
         subject
         expect(response).to have_http_status(:unauthorized)
         expect(response).to render_template('counter_reports/unauthorized')
       end
     end

      context 'already logged in by other entityID' do
        let(:current_user) { create(:user, request_attributes: request_attributes) }
        let(:request_attributes) { { identity_provider: 'other_entity_id' } }

        before { sign_in(current_user) }

        it do
          subject
          expect(response).to redirect_to(shib_login_path(counter_reports_path, params: entity_id))
        end
      end
    end
  end

  context 'Ebook Download' do
    subject { get download_ebook_path(epub.id), params: params }

    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:press) { create(:press) }
    let(:cover) { create(:public_file_set) }
    let(:epub) { create(:public_file_set, allow_download: 'yes') }
    let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:params) { anything }

    before do
      monograph.ordered_members << cover
      monograph.representative_id = cover.id
      monograph.ordered_members << epub
      monograph.save!
      cover.save!
      epub.save!
      fr
    end

    it do
      subject
      expect(response).to redirect_to(hyrax.download_path(epub.id))
    end

    context 'when entityID param' do
      let(:params) { anything.merge(entity_id) }

      it do
        subject
        expect(response).to redirect_to(hyrax.download_path(epub.id))
      end

      context 'restricted' do
        let(:product) { create(:product, identifier: 'product') }
        let(:component) { create(:component, noid: monograph.id) }

        before { product.components << component }

        it do
          subject
          expect(response).to redirect_to(shib_login_path(download_ebook_path(epub.id), params: entity_id))
        end

        context 'open access' do
          before do
            monograph.open_access = 'yes'
            monograph.save!
          end

          it do
            subject
            expect(response).to redirect_to(hyrax.download_path(epub.id))
          end
        end

        context 'already logged in by entityID' do
          let(:current_user) { create(:user, request_attributes: request_attributes) }
          let(:request_attributes) { { identity_provider: params[:entityID] } }

          before { sign_in(current_user) }

          it do
            subject
            expect(response).to have_http_status(:unauthorized)
            expect(response).to render_template('hyrax/base/unauthorized')
          end
        end

        context 'already logged in by other entityID' do
          let(:current_user) { create(:user, request_attributes: request_attributes) }
          let(:request_attributes) { { identity_provider: 'other_entity_id' } }

          before { sign_in(current_user) }

          it do
            subject
            expect(response).to redirect_to(shib_login_path(download_ebook_path(epub.id), params: entity_id))
          end
        end
      end
    end
  end

  context 'EPub Show' do
    subject { get epub_path(epub.id), params: params }

    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:press) { create(:press) }
    let(:cover) { create(:public_file_set) }
    let(:epub) { create(:public_file_set, allow_download: 'yes') }
    let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:params) { anything }

    before do
      monograph.ordered_members << cover
      monograph.representative_id = cover.id
      monograph.ordered_members << epub
      monograph.save!
      cover.save!
      epub.save!
      fr
    end

    it do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context 'when entityID param' do
      let(:params) { anything.merge(entity_id) }

      it do
        subject
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
      end

      context 'restricted' do
        let(:product) { create(:product, identifier: 'product') }
        let(:component) { create(:component, noid: monograph.id) }

        before { product.components << component }

        it do
          subject
          expect(response).to redirect_to(shib_login_path(epub_path(epub.id), params: entity_id))
        end

        context 'open access' do
          before do
            monograph.open_access = 'yes'
            monograph.save!
          end

          it do
            subject
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:show)
          end
        end

        context 'already logged in by entityID' do
          let(:current_user) { create(:user, request_attributes: request_attributes) }
          let(:request_attributes) { { identity_provider: params[:entityID] } }

          before { sign_in(current_user) }

          it do
            subject
            expect(response).to redirect_to(epub_access_path(epub.id))
          end
        end

        context 'already logged in by other entityID' do
          let(:current_user) { create(:user, request_attributes: request_attributes) }
          let(:request_attributes) { { identity_provider: 'other_entity_id' } }

          before { sign_in(current_user) }

          it do
            subject
            expect(response).to redirect_to(shib_login_path(epub_path(epub.id), params: entity_id))
          end
        end
      end
    end
  end
end
