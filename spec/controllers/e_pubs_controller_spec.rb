# frozen_string_literal: true

require 'rails_helper'
require 'json'

RSpec.describe EPubsController, type: :controller do
  it { is_expected.to be_a_kind_of(CheckpointController) }

  context "show" do
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
            expect(response).to have_http_status(:unauthorized)
          end
        end
      end

      context "file epub and the user has an instituion" do
        let(:monograph) { create(:monograph) }
        let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
        let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
        let(:keycard) { { dlpsInstitutionId: [institution.identifier] } }
        let(:institution) { double('institution', identifier: '9999') }

        before do
          monograph.ordered_members << file_set
          monograph.save!
          file_set.save!
          allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
          allow(Institution).to receive(:where).with(identifier: ['9999']).and_return([institution])

          get :show, params: { id: file_set.id }
        end

        after do
          FeaturedRepresentative.destroy_all
          CounterReport.destroy_all
        end

        it "adds to the COUNTER report" do
          expect(CounterReport.count).to eq 1
          expect(CounterReport.first.institution).to eq 9999
          expect(CounterReport.first.investigation).to eq 1
          expect(CounterReport.first.request).to eq 1
          expect(CounterReport.first.access_type).to eq 'OA_Gold'
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
          UnpackJob.perform_now(file_set.id, 'epub')
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
            expect(response.header['X-Sendfile']).to include('META-INF/container.xml')
          end

          context 'access denied' do
            let(:show) { false }

            it do
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
        UnpackJob.perform_now(file_set.id, 'epub')
      end

      after { FeaturedRepresentative.destroy_all }

      context 'finds case insensitive search results' do
        before { get :search, params: { id: file_set.id, q: "White Whale" } }

        it do
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["q"]).to eq "White Whale"
          expect(JSON.parse(response.body)["search_results"].length).to eq 105
          expect(JSON.parse(response.body)["search_results"][0]["cfi"]).to eq "/6/84[xchapter_036]!/4/2/42,/1:66,/1:77"
          expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "“All ye mast-headers have before now heard me give orders about a white whale. Look ye! d’ye see this Spanish ounce of gold?\"—holding up a broad bright coin to the sun—\"it is a sixteen dollar piece, men. D’ye see it? Mr. Starbuck, hand me yon top-maul.”"
          # Only show unique snippets, duplicate neighbor snippets are blank so
          # that they don't display in cozy-sun-bear while we still send all CFIs
          # to get search highlighting
          @snippets = JSON.parse(response.body)["search_results"].map { |result| result["snippet"].presence }.compact
          expect(@snippets.length).to eq 93
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
  end

  context "checkpoint" do
    describe '#set_show' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, id: '999999999', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
      end

      after { FeaturedRepresentative.destroy_all }

      it 'Open Access' do
        session[:show_set] = []
        get :show, params: { id: file_set.id }
        expect(session[:show_set].include?(file_set.id)).to be true
        expect(response).to have_http_status(:success)
      end

      context 'Restricted Access' do
        let(:component) { Component.create!(handle: HandleService.path(file_set.id)) }
        let(:keycard) { { dlpsInstitutionId: dlpsInstitutionId } }
        let(:dlpsInstitutionId) { 'institute' }

        before do
          allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
          component
          session[:show_set] = []
        end

        it 'Anonymous User' do
          get :show, params: { id: file_set.id }
          expect(session[:show_set].include?(file_set.id)).to be false
          expect(response).to render_template(:access)
        end

        it 'Authenticated User' do
          cosign_sign_in(create(:user))
          get :show, params: { id: file_set.id }
          expect(session[:show_set].include?(file_set.id)).to be false
          expect(response).to render_template(:access)
        end

        it 'Platform Admin' do
          cosign_sign_in(create(:platform_admin))
          get :show, params: { id: file_set.id }
          expect(session[:show_set].include?(file_set.id)).to be false
          expect(response).to have_http_status(:success)
        end

        it "Subscribed Institution" do
          institution = Institution.create!(identifier: dlpsInstitutionId, name: 'Name', site: 'Site', login: 'Login')
          product = Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
          product.components << component
          # lessee = Lessee.find_by(identifier: dlpsInstitutionId)
          # product.lessees << lessee
          product.save!
          agent = PolicyAgent.new(Institution, institution)
          credential = PolicyCredential.new(:Action, :show)
          resource = PolicyResource.new(Product, product)
          Checkpoint::DB::Permit.from(agent, credential, resource, zone: Checkpoint::DB::Permit.default_zone).save
          _permits = Checkpoint::DB::Permit.all

          get :show, params: { id: file_set.id }
          expect(session[:show_set].include?(file_set.id)).to be false
          expect(response).to have_http_status(:success)
        end

        it "Subscribed User" do
          user = create(:user)
          product = Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
          product.components << component
          lessee = Lessee.create!(identifier: user.email)
          product.lessees << lessee
          product.save!
          cosign_sign_in(user)
          get :show, params: { id: file_set.id }
          expect(session[:show_set].include?(file_set.id)).to be true
          expect(response).to have_http_status(:success)
        end
      end
    end

    describe 'session[:set_show]' do
      let(:presenter) { double('presenter', id: 'id', epub?: true, citable_link: 'link', monograph_id: 'mono_id') }
      let(:parent) { double('monograph_presenter', title: 'Title', subdomain: 'subdomain', id: 'mono_id') }

      let(:n) { 20 }
      let(:m) { 10 }

      before do
        allow(Hyrax::PresenterFactory).to receive(:build_for).and_return([presenter])
        allow(presenter).to receive(:parent).and_return(parent)
        allow(presenter).to receive(:monograph).and_return(parent)
      end

      it 'buffers m ids' do
        session[:show_set] = []
        n.times do |i|
          get :show, params: { id: i }
          expect(response).to have_http_status(:success)
          expect(session[:show_set].include?(i.to_s)).to be true
          expect(session[:show_set].length).to be <= m
        end
      end
    end

    describe '#download_chapter' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, id: '999999999', content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        UnpackJob.perform_now(file_set.id, 'epub')
      end

      after { FeaturedRepresentative.destroy_all }

      it 'sends the chapter as pdf' do
        get :download_chapter, params: { id: file_set.id, cfi: '/6/2[xhtml00000003]!' }
        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Type']).to eq 'application/pdf'
        expect(response.headers['Content-Disposition']).to eq 'inline'
        expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
        expect(response.body.starts_with?("%PDF-1.3\n")).to be true
      end
    end

    describe '#download_interval' do
      let(:monograph) { create(:monograph) }
      let(:file_set) { create(:file_set, id: '999999998', content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
      let!(:fr) { create(:featured_representative, monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
      let(:document) { double('document') }
      let(:rendered) { "%PDF-1.3\n" }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        UnpackJob.perform_now(file_set.id, 'epub')
        allow_any_instance_of(described_class).to receive(:show?).and_return(true)
        allow(Prawn::Document).to receive(:new).and_return(document)
      end

      after { FeaturedRepresentative.destroy_all }

      it 'sends the interval as pdf' do
        expect(document).to receive(:image).with(/images\/00000003\.png/, fit: [512, 692])
        expect(document).to receive(:image).with(/images\/00000004\.png/, fit: [512, 692])
        expect(document).to receive(:image).with(/images\/00000005\.png/, fit: [512, 692])
        expect(document).to receive(:render).and_return(rendered)
        expect(controller).to receive(:send_data).with(rendered, type: "application/pdf", disposition: "inline").and_call_original
        get :download_interval, params: { id: file_set.id, cfi: '/6/2[xhtml00000003]!/4/1:0', title: "This is Chapter One's Title" }
        expect(response).to have_http_status(:success)
        expect(response.headers['Content-Type']).to eq 'application/pdf'
        expect(response.headers['Content-Disposition']).to eq 'inline'
        expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
        expect(response.body.starts_with?("%PDF-1.3\n")).to be true
      end
    end
  end
end
