# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubController, type: :controller do
  describe "GET #show" do
    context 'not found' do
      before { get :show, id: :id }
      it { expect(response).to have_http_status(:unauthorized) }
    end
    context 'file nil' do
      let(:file_set) { create(:file_set) }

      before { get :show, id: file_set.id }
      it { expect(response).to have_http_status(:unauthorized) }
    end
    context 'file not epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

      before { get :show, id: file_set.id }
      it { expect(response).to have_http_status(:unauthorized) }
    end
    context 'file epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }

      before { get :show, id: file_set.id }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "GET #file" do
    context 'not found' do
      before { get :file, id: :id, file: 'META-INF/container', format: 'xml' }
      it { expect(response).to have_http_status(:unauthorized) }
    end
    context 'file nil' do
      let(:file_set) { create(:file_set) }

      before { get :file, id: file_set.id, file: 'META-INF/container', format: 'xml' }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end
    context 'file not epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

      before { get :file, id: file_set.id, file: 'META-INF/container', format: 'xml' }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end
    context 'file epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }

      context 'file not found' do
        before { get :file, id: file_set.id, file: 'META-INF/container', format: 'txt' }
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be true
        end
      end
      context 'file exist' do
        before { get :file, id: file_set.id, file: 'META-INF/container', format: 'xml' }
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be false
        end
      end
    end
  end
end
