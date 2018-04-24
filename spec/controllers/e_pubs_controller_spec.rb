# frozen_string_literal: true

require 'rails_helper'
require 'json'

RSpec.describe EPubsController, type: :controller do
  let(:show) { true }

  before { allow_any_instance_of(described_class).to receive(:show?).and_return(show) }

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
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end

      context 'access denied' do
        let(:show) { false }

        it do
          expect(response).to have_http_status(:redirect)
          expect(response).to redirect_to(epub_lock_path)
        end
      end
    end
  end

  describe "#file" do
    context 'not found' do
      before { get :file, params: { id: :id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end

    context 'file nil' do
      let(:file_set) { create(:file_set, id: '111111119') }

      before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
      it do
        expect(response).to have_http_status(:success)
        expect(response.body.empty?).to be true
      end
    end

    context 'file not epub' do
      let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

      before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
      it do
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
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be true
        end
      end

      context 'file exist' do
        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }
        it do
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be false
          expect(response.header['Content-Type']).to include('application/xml')
        end

        context 'access denied' do
          let(:show) { false }
          it do
            expect(response).to have_http_status(:success)
            expect(response.body.empty?).to be true
          end
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

      context 'access denied' do
        let(:show) { false }

        it do
          expect(response).to have_http_status(:not_found)
          expect(response.body.empty?).to be true
        end
      end
    end

    context "searches must be 3 or more characters" do
      before { get :search, params: { id: file_set.id, q: "no" } }

      it do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["q"]).to eq "no"
        expect(JSON.parse(response.body)["search_results"].length).to eq 0
      end
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

    context "when the search query is not found" do
      before { get :search, params: { id: file_set.id, q: "glubmerschmup" } }
      it "returns an empty list" do
        expect(response).to have_http_status(:success)
        expect(JSON.parse(response.body)["q"]).to eq "glubmerschmup"
        expect(JSON.parse(response.body)["search_results"]).to eq []
      end
    end
  end

  describe '#lock' do
    let(:monograph) { create(:monograph) }
    let(:file_set) { create(:file_set, id: '999999999', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
    let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    after { FeaturedRepresentative.destroy_all }

    context 'institution subscription' do
      let(:keycard) { { "dlpsInstitutionId" => dlpsInstitutionId } }
      let(:dlpsInstitutionId) { 'institute' }

      before { allow_any_instance_of(Keycard::RequestAttributes).to receive(:all).and_return(keycard) }

      it do
        # Open Access
        session[:show_set] = []
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be true
        expect(response).to redirect_to(epub_path)

        # Restricted Access
        component = Component.create!(handle: HandleService.handle(file_set))

        # Anonymous User
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be false
        expect(response).to render_template(:access)

        # Subscribed Institution
        product = Product.create!(identifier: 'product', purchase: 'purchase')
        product.components << component
        lessee = Lessee.create!(identifier: dlpsInstitutionId)
        product.lessees << lessee
        product.save!
        Institution.create!(key: dlpsInstitutionId, name: 'Name', site: 'Site', login: 'Login')
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be true
        expect(response).to redirect_to(epub_path)
      end
    end

    context 'user subscription' do
      let(:user) { create(:user) }

      it do
        # Open Access
        session[:show_set] = []
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be true
        expect(response).to redirect_to(epub_path)

        # Restricted Access
        component = Component.create!(handle: HandleService.handle(file_set))

        # Anonymous User
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be false
        expect(response).to render_template(:access)

        # Authenticated User
        cosign_sign_in(user)
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be false
        expect(response).to render_template(:access)

        # Subscribed User
        product = Product.create!(identifier: 'product', purchase: 'purchase')
        product.components << component
        lessee = Lessee.create!(identifier: user.email)
        product.lessees << lessee
        product.save!
        get :lock, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be true
        expect(response).to redirect_to(epub_path)
      end
    end
  end
end
