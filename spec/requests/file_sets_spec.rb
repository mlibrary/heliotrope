# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "FileSets", type: :request do
  context 'draft monograph file set' do
    let(:press) { create(:press) }
    let(:monograph) { create(:monograph, press: press.subdomain) }
    let(:file_set) { create(:file_set) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    describe 'GET /concern/file_sets/:id' do
      it do
        get hyrax_file_set_path(file_set.id)
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  context 'published monograph file set' do
    let(:press) { create(:press) }
    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:file_set) { create(:public_file_set, resource_type: [resource_type], permissions_expiration_date: permissions_expiration_date) }
    let(:resource_type) { 'resource_type' }
    let(:permissions_expiration_date) { }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    describe 'GET /concern/file_sets/:id' do
      it do
        get hyrax_file_set_path(file_set.id)
        expect(response).to have_http_status(:ok)
        expect(response).to render_template(:show)
        expect(response).to have_rendered('_side_by_side_layout')
        expect(response).not_to have_rendered('_stacked_layout')
        expect(response).not_to have_rendered('_media_tombstone')
      end

      context 'map' do
        let(:resource_type) { 'interactive map' }

        it do
          get hyrax_file_set_path(file_set.id)
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
          expect(response).not_to have_rendered('_side_by_side_layout')
          expect(response).to have_rendered('_stacked_layout')
          expect(response).not_to have_rendered('_media_tombstone')
        end
      end

      context 'tombstone' do
        let(:permissions_expiration_date) { Date.yesterday.strftime("%Y-%m-%d") }

        it do
          get hyrax_file_set_path(file_set.id)
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
          expect(response).to have_rendered('_side_by_side_layout')
          expect(response).not_to have_rendered('_stacked_layout')
          expect(response).to have_rendered('_media_tombstone')
        end
      end
    end
  end
end
