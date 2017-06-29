# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubController, type: :controller do
  describe "GET #show" do
    context 'not found' do
      before { get :show, params: { id: :id } }
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'file nil' do
      let(:file_set) { create(:file_set) }

      before { get :show, params: { id: file_set.id } }
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'file not epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

      before { get :show, params: { id: file_set.id } }
      it { expect(response).to have_http_status(:unauthorized) }
    end

    context 'file epub' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        get :show, params: { id: file_set.id }
      end
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
      end
    end

    context 'tombstone' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        file_set.destroy!
        get :show, params: { id: file_set.id }
      end
      it do
        # The HTTP response status code 302 Found is a common way of performing URL redirection.
        expect(response).to have_http_status(:found)
        # raise CanCan::AccessDenied currently redirects to root_url
        expect(response.header["Location"]).to match "http://test.host/"
      end
    end
  end

  describe "GET #file" do
    context 'not found' do
      before { get :file, params: { id: :id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:not_found)
        expect(response.body.empty?).to be true
      end
    end

    context 'file nil' do
      let(:file_set) { create(:file_set) }

      before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:not_found)
        expect(response.body.empty?).to be true
      end
    end

    context 'file not epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

      before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:not_found)
        expect(response.body.empty?).to be true
      end
    end

    context 'file epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }

      context 'file not found' do
        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'txt' } }
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:not_found)
          expect(response.body.empty?).to be true
        end
      end

      context 'file exist' do
        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be false
        end
      end

      context 'tombstone' do
        before do
          file_set.destroy!
          get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' }
        end
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:not_found)
          expect(response.body.empty?).to be true
        end
      end
    end
  end
end
