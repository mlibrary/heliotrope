# frozen_string_literal: true

require 'rails_helper'
require 'json'

RSpec.describe EPubsController, type: :controller do
  describe "#show" do
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
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        get :show, params: { id: file_set.id }
      end
      after { FeaturedRepresentative.destroy_all }
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

  describe "#file" do
    context 'not found' do
      before { get :file, params: { id: :id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end

    context 'file nil' do
      let(:file_set) { create(:file_set, id: '111111119') }

      before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end

    context 'file not epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

      before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to_not have_http_status(:unauthorized)
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end

    context 'file epub' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
      end
      after { FeaturedRepresentative.destroy_all }

      context 'file not found' do
        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'txt' } }
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be true
        end
      end

      context 'file exist' do
        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
        it do
          expect(response).to_not have_http_status(:unauthorized)
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be false
          expect(response.header['Content-Type']).to include('application/xml')
        end
      end

      context 'tombstone' do
        before do
          EPub::Cache.purge(file_set.id)
          file_set.destroy!
          get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' }
        end

        it "is destroyed" do
          expect(file_set.destroyed?).to be true
        end

        context "after destroy" do
          before do
            get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' }
          end
          it "is not found" do
            expect(response).to_not have_http_status(:unauthorized)
            expect(response).to have_http_status(:success)
            expect(response.body.empty?).to be true
          end
        end
      end
    end
  end

  describe "GET #search" do
    let(:monograph) { create(:monograph) }
    let(:file_set) { create(:file_set, id: '999999999', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
    let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end
    after { FeaturedRepresentative.destroy_all }

    context 'finds case insensitive search results' do
      before { get :search, params: { id: file_set.id, q: "White Whale" } }

      it do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["q"]).to eq "White Whale"
        expect(JSON.parse(response.body)["search_results"].length).to eq 95
        expect(JSON.parse(response.body)["search_results"][0]["cfi"]).to eq "/6/84[xchapter_036]!/4/2/42,/1:66,/1:77"
        expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "“All ye mast-headers have before now heard me give orders about a white whale. Look ye! d’ye see this Spanish ounce of gold?\"—holding up a broad bright coin to the sun—\"it is a sixteen dollar piece, men. D’ye see it? Mr. Starbuck, hand me yon top-maul.”"
      end
    end

    context 'finds hypenated search results' do
      before { get :search, params: { id: file_set.id, q: "bell-boy" } }

      it do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["search_results"].length).to eq 3
      end
    end

    context "searches must be 3 or more characters" do
      before { get :search, params: { id: file_set.id, q: "no" } }

      it { expect(response).to have_http_status(:not_found) }
    end

    context "if a search is cached, return the cached search" do
      let(:results) do
        { q: 'search term',
          search_results: [
            cfi: "/6/84/[chap]!/4/2/2/,/1:66,/1:77",
            snippet: "This is a snippet"
          ] }
      end

      before do
        allow(Rails.cache).to receive(:fetch).and_return(results)
        get :search, params: { id: file_set.id, q: "White Whale" }
      end

      it do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["search_results"].length).to eq 1
        expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "This is a snippet"
      end
    end
  end
end
