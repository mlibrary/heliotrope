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
    let(:file_set) { create(:public_file_set, resource_type: [resource_type]) }
    let(:resource_type) { '' }

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
        let(:resource_type) { 'map' }

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
        before { allow(Sighrax).to receive(:tombstone?).with(anything).and_return(true) }

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
