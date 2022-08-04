# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Epub Ebooks", type: :request do
  context 'Princesse De Cleves' do
    let(:monograph) {
      create(:public_monograph,
             user: user,
             press: press.subdomain,
             isbn: isbn,
             representative_id: cover.id,
             thumbnail_id: thumbnail.id)
    }
    let(:user) { create(:user) }
    let(:press) { create(:press) }
    let(:isbn) { ['978-1-64315-038-3 (ebook)'] }
    let(:cover) { create(:public_file_set) }
    let(:thumbnail) { create(:public_file_set) }
    let(:epub) { create(:public_file_set, id: 'pdecleves', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
    let(:counter_service) { double('counter_service') }
    let(:fre) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:ebook_reader_op) { instance_double(EbookReaderOperation, 'ebook_reader_op', allowed?: allowed) }

    before do
      stub_out_irus
      monograph.ordered_members = [cover, thumbnail, epub]
      [monograph, cover, thumbnail, epub].map(&:save!)
      fre
      allow(EbookReaderOperation).to receive(:new).and_return ebook_reader_op
      allow(CounterService).to receive(:from).and_return counter_service
      allow(counter_service).to receive(:count).with(request: 1)
    end

    context "authorizations" do
      let(:publication) { EPub::Publication.null_object }

      before { allow(EPub::Publication).to receive(:from_directory).with(UnpackService.root_path_from_noid(epub.id, 'epub')).and_return publication }

      context 'unauthorized' do
        let(:allowed) { false }

        describe 'GET /epub_ebooks/pdecleves' do
          subject { get "/epub_ebooks/#{epub.id}" }

          it do
            expect { subject }.not_to raise_error
            expect(counter_service).not_to have_received(:count).with(request: 1)
            expect(response).to have_http_status(:unauthorized)
            expect(response).to render_template('hyrax/base/unauthorized')
          end
        end
      end

      context 'authorized, but id is for a Monograph with wrong ISBN (not PdC)' do
        let(:allowed) { true }
        let(:isbn) { ['999-1-64315-038-3 (ebook)'] }

        describe 'GET /epub_ebooks/pdecleves' do
          subject { get "/epub_ebooks/#{epub.id}" }

          it do
            expect { subject }.not_to raise_error
            expect(counter_service).not_to have_received(:count).with(request: 1)
            expect(response).to have_http_status(:not_found)
            expect(response).to render_template(file: Rails.root.join('public', '404.html').to_s)
          end
        end
      end

      context 'authorized' do
        let(:allowed) { true }

        describe 'GET /epub_ebooks/pdecleves' do
          subject { get "/epub_ebooks/#{epub.id}" }

          it do
            expect { subject }.not_to raise_error
            expect(counter_service).to have_received(:count).with(request: 1)
            expect(response).to have_http_status(:ok)
            expect(response).to render_template(:show)
            expect(response).to render_template('layouts/csb_too_viewer')
            expect(response).to render_template('epub_ebooks/show')
            expect(response).to render_template('epub_ebooks/_cozy_controls_top')
            expect(response).to render_template('epub_ebooks/_cozy_controls_bottom')
          end
        end
      end
    end

    # HELIO-4285 Way too much of this just taken from  e_pubs_controller_spec
    # Someday we should remove all this specific Princesse De Cleves controller stuff and
    # integrate it into the e_pub_controller. It's weird it's its own thing.
    describe "#search" do
      let(:allowed) { true }

      before do
        UnpackJob.perform_now(epub.id, 'epub')
      end

      after { FeaturedRepresentative.destroy_all }

      context 'finds case insensitive search results' do
        before { get "/epub_ebooks/#{epub.id}/search?q=White%20Whale" }

        it do
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["q"]).to eq "White Whale"
          expect(JSON.parse(response.body)["search_results"].length).to eq 105
          expect(JSON.parse(response.body)["search_results"][0]["cfi"]).to eq "/6/84[xchapter_036]!/4/2/42,/1:66,/1:77"
          expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "“All ye mast-headers have before now heard me give orders about a white whale. Look ye! d’ye see this Spanish ounce of"
          # Only show unique snippets, duplicate neighbor snippets are blank so
          # that they don't display in cozy-sun-bear while we still send all CFIs
          # to get search highlighting
          @snippets = JSON.parse(response.body)["search_results"].filter_map { |result| result["snippet"].presence }
          expect(@snippets.length).to eq 102
          expect(EpubSearchLog.first.noid).to eq epub.id
          expect(EpubSearchLog.first.query).to eq "White Whale"
          expect(EpubSearchLog.first.hits).to eq 105
        end
      end

      context 'finds hypenated search results' do
        before { get "/epub_ebooks/#{epub.id}/search?q=bell-boy" }

        it do
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["search_results"].length).to eq 3
        end

        context 'access denied' do
          let(:allowed) { false }

          it do
            expect(response).to have_http_status(:not_found)
            expect(response.body.empty?).to be true
          end
        end
      end

      context "searches must be 3 or more characters" do
        before { get "/epub_ebooks/#{epub.id}/search?q=no" }

        it do
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["q"]).to eq "no"
          expect(JSON.parse(response.body)["search_results"].length).to eq 0
        end
      end

      context "caching search queries" do
        let(:cached_results) do
          { q: 'cached search term',
            search_results: [
              cfi: "/6/84/[chap]!/4/2/2/,/1:66,/1:77",
              snippet: "This is a snippet"
            ] }
        end

        context "normal users get cached search results if there are any" do
          before do
            allow(Rails.cache).to receive(:fetch).and_return(cached_results)
            get "/epub_ebooks/#{epub.id}/search?q=White%20Whale"
          end

          it do
            expect(response).to have_http_status(:success)
            expect(JSON.parse(response.body)["search_results"].length).to eq 1
            expect(JSON.parse(response.body)["q"]).to eq "cached search term"
            expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "This is a snippet"
          end
        end

        context "platform_admins do not get cached search results" do
          let(:user) { create(:platform_admin) }

          before do
            sign_in user
            allow(Rails.cache).to receive(:fetch).and_return(cached_results)
            get "/epub_ebooks/#{epub.id}/search?q=White%20Whale"
          end

          it do
            expect(response).to have_http_status(:success)
            expect(JSON.parse(response.body)["search_results"].length).to eq 105
            expect(JSON.parse(response.body)["q"]).to eq "White Whale"
            expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "“All ye mast-headers have before now heard me give orders about a white whale. Look ye! d’ye see this Spanish ounce of"
            expect(EpubSearchLog.first.user).to eq user.email
            expect(EpubSearchLog.first.press).to eq press.subdomain
            expect(EpubSearchLog.first.session_id).to eq request.session.id.to_s
          end
        end
      end

      context "when the search query is not found" do
        before { get "/epub_ebooks/#{epub.id}/search?q=glubmerschmup" }

        it "returns an empty list" do
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["q"]).to eq "glubmerschmup"
          expect(JSON.parse(response.body)["search_results"]).to eq []
          expect(EpubSearchLog.first.noid).to eq epub.id
          expect(EpubSearchLog.first.query).to eq "glubmerschmup"
          expect(EpubSearchLog.first.hits).to eq 0
        end
      end
    end
  end
end
