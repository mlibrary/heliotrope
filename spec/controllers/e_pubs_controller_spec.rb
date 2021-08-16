# frozen_string_literal: true

require 'rails_helper'
require 'json'

RSpec.describe EPubsController, type: :controller do
  it { is_expected.to be_a_kind_of(CheckpointController) }

  context 'policy' do
    let(:policy) { double('policy') }
    let(:access) { true }

    before do
      allow(EPubPolicy).to receive(:new).and_return(policy)
      allow(policy).to receive(:show?).and_return(access)
    end

    describe '#show' do
      context 'not found' do
        let(:presenter) { double('presenter', solr_document: {}) }

        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).and_return([presenter])
          get :show, params: { id: 'validnoid' }
        end

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
        let(:monograph) { create(:public_monograph, title: ['A book with _emphasis_ n <em>stuff</em>']) }
        let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
        let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

        before do
          monograph.ordered_members << file_set
          monograph.save!
          file_set.save!
        end

        after { FeaturedRepresentative.destroy_all }

        it do
          get :show, params: { id: file_set.id }
          expect(assigns(:title)).to eq('A book with emphasis n stuff')
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response.body.empty?).to be true
        end

        context 'access denied' do
          let(:access) { false }

          it do
            get :show, params: { id: file_set.id }
            expect(response).to have_http_status(:found)
            expect(response).to redirect_to(epub_access_url)
          end
        end
      end

      context "file epub and the user has an institution" do
        let(:monograph) { create(:public_monograph) }
        let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
        let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
        let(:keycard) { { dlpsInstitutionId: [dlps_institution_id.to_s] } }
        let(:institution) { create(:institution, identifier: dlps_institution_id.to_s) }
        let(:institution_affiliation) { create(:institution_affiliation, institution: institution, dlps_institution_id: dlps_institution_id, affiliation: 'member') }
        let(:dlps_institution_id) { 9999 }

        before do
          institution_affiliation
          monograph.ordered_members << file_set
          monograph.save!
          file_set.save!
          allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)

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

    describe '#file' do
      context 'not found' do
        let(:presenter) { double('presenter', solr_document: {}) }

        before do
          allow(Hyrax::PresenterFactory).to receive(:build_for).and_return([presenter])
          get :file, params: { id: 'validnoid', file: 'META-INF/container', format: 'xml' }
        end

        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'file nil' do
        let(:file_set) { create(:file_set, id: '111111119') }

        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }

        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'file not epub' do
        let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'it.mp4'))) }

        before { get :file, params: { id: file_set.id, file: 'META-INF/container', format: 'xml' } }

        it { expect(response).to have_http_status(:unauthorized) }
      end

      context 'file epub' do
        let(:monograph) { create(:public_monograph) }
        let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
        let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

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
            expect(response.header['Content-Type']).to be_nil
            expect(response.header['X-Sendfile']).to be_empty
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
            let(:access) { false }

            it do
              expect(response).to have_http_status(:no_content)
              expect(response.body.empty?).to be true
            end
          end
        end
      end

      context 'file pdf' do
        let(:monograph) { create(:public_monograph) }
        let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'dummy.pdf'))) }
        let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'pdf_ebook') }

        before do
          monograph.ordered_members << file_set
          monograph.save!
          file_set.save!
        end

        context 'pdf is not unpacked (exists only in fedora)' do
          before { get :file, params: { id: file_set.id, file: 'file' } }

          it do
            expect(response).to have_http_status(:success)
            expect(response.body.empty?).to be false
            expect(response.header['X-Sendfile']).to be_nil
            expect(response.header['Accept-Ranges']).to be_nil
          end
        end

        context 'pdf is unpacked (exists in derivatives directory)' do
          before do
            UnpackJob.perform_now(file_set.id, 'pdf_ebook')
          end

          after do
            FileUtils.remove_entry_secure(UnpackService.root_path_from_noid(file_set.id, 'pdf_ebook') + '.pdf')
          end

          it do
            get :file, params: { id: file_set.id, file: 'file' }
            expect(response).to have_http_status(:success)
            expect(response.body.empty?).to be false
            expect(response.header['X-Sendfile']).to include("#{file_set.id.last}-pdf_ebook.pdf")
            expect(response.header['Accept-Ranges']).to eq 'bytes'
          end
        end
      end
    end

    describe '#search' do
      let(:monograph) { create(:public_monograph) }
      let(:file_set) { create(:public_file_set, id: '999999999', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

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
          expect(JSON.parse(response.body)["search_results"][0]["snippet"]).to eq "“All ye mast-headers have before now heard me give orders about a white whale. Look ye! d’ye see this Spanish ounce of"
          # Only show unique snippets, duplicate neighbor snippets are blank so
          # that they don't display in cozy-sun-bear while we still send all CFIs
          # to get search highlighting
          @snippets = JSON.parse(response.body)["search_results"].map { |result| result["snippet"].presence }.compact
          expect(@snippets.length).to eq 102
          expect(EpubSearchLog.first.noid).to eq file_set.id
          expect(EpubSearchLog.first.query).to eq "White Whale"
          expect(EpubSearchLog.first.hits).to eq 105
        end
      end

      context 'finds hypenated search results' do
        before { get :search, params: { id: file_set.id, q: "bell-boy" } }

        it do
          expect(response).to have_http_status(:success)
          expect(JSON.parse(response.body)["search_results"].length).to eq 3
        end

        context 'access denied' do
          let(:access) { false }

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
          expect(EpubSearchLog.first.noid).to eq file_set.id
          expect(EpubSearchLog.first.query).to eq "glubmerschmup"
          expect(EpubSearchLog.first.hits).to eq 0
        end
      end
    end
  end

  context "checkpoint" do
    describe '#show' do
      let(:press) { create(:press) }
      let(:monograph) { create(:public_monograph, press: press.subdomain) }
      let(:file_set) { create(:public_file_set, id: '999999999', content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
      end

      after { FeaturedRepresentative.destroy_all }

      it 'Open Access' do
        get :show, params: { id: file_set.id }
        expect(assigns(:actor_product_ids))
        expect(assigns(:allow_read_product_ids))
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end

      context 'Restricted Access' do
        let(:parent) { Sighrax.from_noid(monograph.id) }
        let(:epub) { Sighrax.from_noid(file_set.id) }
        let(:component) { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }
        let(:keycard) { { dlpsInstitutionId: dlpsInstitutionId } }
        let(:dlpsInstitutionId) { '0' }

        before do
          clear_grants_table
          allow_any_instance_of(Keycard::Request::Attributes).to receive(:all).and_return(keycard)
          component
        end

        it 'Anonymous User' do
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(epub_access_url)
        end

        it 'Authenticated User' do
          sign_in(create(:user))
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(epub_access_url)
        end

        it 'Platform Admin' do
          sign_in(create(:platform_admin))
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end

        it 'Press Admin' do
          sign_in(create(:press_admin, press: press))
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end

        it 'Press Editor' do
          sign_in(create(:press_editor, press: press))
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end

        it 'Press Analyst' do
          sign_in(create(:press_analyst, press: press))
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end

        it "Subscribed Greensub::Institution" do
          institution = create(:institution, identifier: dlpsInstitutionId)
          product = Greensub::Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
          product.components << component
          product.save!
          institution.update_product_license(product)
          create(:institution_affiliation, institution_id: institution.id, affiliation: "member")
          create(:license_affiliation, license_id: institution.product_license(product).id, affiliation: "member")
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end

        it "Subscribed Greensub::Institution with the wrong affiliation" do
          institution = create(:institution, identifier: dlpsInstitutionId)
          product = Greensub::Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
          product.components << component
          product.save!
          institution.update_product_license(product)
          create(:institution_affiliation, institution_id: institution.id, affiliation: "alum")
          create(:license_affiliation, license_id: institution.product_license(product).id, affiliation: "member")
          allow(Incognito).to receive(:developer?).and_return true # TODO: remvove
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(epub_access_url)
        end

        it "Subscribed Individual" do
          email = 'wolverine@umich.edu'
          user = create(:user, email: email)
          individual = create(:individual, identifier: email, email: email)
          product = Greensub::Product.create!(identifier: 'product', name: 'name', purchase: 'purchase')
          product.components << component
          product.save!
          individual.update_product_license(product)
          sign_in(user)
          get :show, params: { id: file_set.id }
          expect(assigns(:actor_product_ids))
          expect(assigns(:allow_read_product_ids))
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
        end
      end
    end

    describe '#download_chapter' do
      let(:monograph) { create(:public_monograph) }
      let(:file_set) { create(:public_file_set, id: '999999999', content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        UnpackJob.perform_now(file_set.id, 'epub')
        allow_any_instance_of(EPubPolicy).to receive(:show?).and_return(true)
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
      let(:ebook_interval_download_op) { instance_double(EbookIntervalDownloadOperation, 'ebook_interval_download_op', allowed?: true) }
      let(:counter_service) { double('counter_service') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
        allow(EbookIntervalDownloadOperation).to receive(:new).with(anything, Sighrax.from_noid(file_set.id)).and_return ebook_interval_download_op
        allow(CounterService).to receive(:from).and_return(counter_service)
        allow(counter_service).to receive(:count).with(request: 1, section: "This is Chapter One's Title", section_type: 'Chapter')
      end

      after { FeaturedRepresentative.destroy_all }

      context 'fixed-layout (fixed-width) EPUB ebook' do
        let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
        let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

        before do
          UnpackJob.perform_now(file_set.id, 'epub')
          allow(UnpackService).to receive(:root_path_from_noid).and_return(fixture_path)
        end

        context 'inadequate metadata to create the full citation in the watermark/stamp' do
          it 'sends the interval as pdf' do
            get :download_interval, params: { id: file_set.id, title: "This is Chapter One's Title", chapter_index: 0 }
            expect(assigns(:entity))
            expect(response).to have_http_status(:ok)
            expect(response.headers['Content-Type']).to eq 'application/pdf'
            expect(response.headers['Content-Disposition']).to eq 'inline; filename="0_This_is_Chapter_One_s_Title.pdf"'
            expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
            # watermarking will change the file content and add fonts
            expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, '0.pdf'))
            expect(response.body).to include('OpenSans-Regular')
            expect(response.body).to include('OpenSans-Italic')
            expect(counter_service).to have_received(:count).with(request: 1, section: "This is Chapter One's Title", section_type: 'Chapter')
          end
        end

        context 'adequate metadata to create a cover page' do
          let(:monograph) { create(:monograph, creator: ['Doe, A. Deer'], date_created: ['2003'],
                                   location: 'Collegeville, MN', publisher: ['Uni Press']) }

          it 'sends the interval as pdf' do
            get :download_interval, params: { id: file_set.id, title: "This is Chapter One's Title", chapter_index: 0 }
            expect(assigns(:entity))
            expect(response).to have_http_status(:ok)
            expect(response.headers['Content-Type']).to eq 'application/pdf'
            expect(response.headers['Content-Disposition']).to eq 'inline; filename="0_This_is_Chapter_One_s_Title.pdf"'
            expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
            # watermarking will change the file content and add fonts
            expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, '0.pdf'))
            expect(response.body).to include('OpenSans-Regular')
            expect(response.body).to include('OpenSans-Italic')
            expect(counter_service).to have_received(:count).with(request: 1, section: "This is Chapter One's Title", section_type: 'Chapter')
          end
        end
      end

      context 'PDF ebook' do
        let(:file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'lorum_ipsum_toc.pdf'))) }
        let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'pdf_ebook') }

        before do
          UnpackJob.perform_now(file_set.id, 'pdf_ebook')
          allow(UnpackService).to receive(:root_path_from_noid).and_return(fixture_path)
        end

        context 'inadequate metadata to create the full citation in the watermark/stamp' do
          it 'sends the interval as pdf' do
            get :download_interval, params: { id: file_set.id, title: "This is Chapter One's Title", chapter_index: 0 }
            expect(assigns(:entity))
            expect(response).to have_http_status(:ok)
            expect(response.headers['Content-Type']).to eq 'application/pdf'
            expect(response.headers['Content-Disposition']).to eq 'inline; filename="0_This_is_Chapter_One_s_Title.pdf"'
            expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
            # watermarking will change the file content and add fonts
            expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, '0.pdf'))
            expect(response.body).to include('OpenSans-Regular')
            expect(response.body).to include('OpenSans-Italic')
            expect(counter_service).to have_received(:count).with(request: 1, section: "This is Chapter One's Title", section_type: 'Chapter')
          end
        end

        context 'adequate metadata to create a cover page' do
          let(:monograph) { create(:monograph, creator: ['Doe, A. Deer'], date_created: ['2003'],
                                   location: 'Collegeville, MN', publisher: ['Uni Press']) }

          it 'sends the interval as pdf' do
            get :download_interval, params: { id: file_set.id, title: "This is Chapter One's Title", chapter_index: 0 }
            expect(assigns(:entity))
            expect(response).to have_http_status(:ok)
            expect(response.headers['Content-Type']).to eq 'application/pdf'
            expect(response.headers['Content-Disposition']).to eq 'inline; filename="0_This_is_Chapter_One_s_Title.pdf"'
            expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
            # watermarking will change the file content and add fonts
            expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, '0.pdf'))
            expect(response.body).to include('OpenSans-Regular')
            expect(response.body).to include('OpenSans-Italic')
            expect(counter_service).to have_received(:count).with(request: 1, section: "This is Chapter One's Title", section_type: 'Chapter')
          end
        end
      end
    end

    describe "#show share link" do
      let(:monograph) { create(:public_monograph) }
      let(:file_set) { create(:public_file_set, id: '888888888', content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
      let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      before do
        monograph.ordered_members << file_set
        monograph.save!
        file_set.save!
      end

      context "A restricted epub with an anonymous user" do
        let(:valid_share_token) do
          JsonWebToken.encode(data: file_set.id, exp: Time.now.to_i + 48 * 3600)
        end
        let(:expired_share_token) do
          JsonWebToken.encode(data: file_set.id, exp: Time.now.to_i - 1000)
        end
        let(:wrong_share_token) do
          JsonWebToken.encode(data: 'wrongnoid', exp: Time.now.to_i + 48 * 3600)
        end
        let(:parent) { Sighrax.from_noid(monograph.id) }
        let(:epub) { Sighrax.from_noid(file_set.id) }

        before do
          Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid)
        end

        it "with a valid share_link" do
          get :show, params: { id: file_set.id, share: valid_share_token }
          expect(response).to have_http_status(:success)
          expect(response).to render_template(:show)
          expect(ShareLinkLog.count).to eq 1
          expect(ShareLinkLog.last.action).to eq 'use'
          expect(ShareLinkLog.last.title).to eq monograph.title.first
          expect(ShareLinkLog.last.noid).to eq file_set.id
          expect(ShareLinkLog.last.token).to eq valid_share_token
        end

        it "with an expired share_link" do
          get :show, params: { id: file_set.id, share: expired_share_token }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(epub_access_url)
          expect(ShareLinkLog.count).to eq 0
        end

        it "with the wrong share link" do
          get :show, params: { id: file_set.id, share: wrong_share_token }
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(epub_access_url)
          expect(ShareLinkLog.count).to eq 0
        end
      end
    end
  end

  describe '#share_link' do
    let(:mono) do
      ::SolrDocument.new(id: '111111111',
                         has_model_ssim: ['Monograph'],
                         title_tesim: ['_Red_'],
                         press_tesim: press.subdomain,
                         member_ids_ssim: ['222222222'])
    end
    let(:epub) do
      ::SolrDocument.new(id: '222222222',
                         has_model_ssim: ['FileSet'],
                         title_tesim: ['Blue'],
                         monograph_id_ssim: ['111111111'])
    end
    let(:policy) { double('policy') }
    let(:access) { true }
    let(:share_link_expiration_time) { 28 * 24 * 3600 } # 28 days in seconds
    let(:now) { Time.now }

    before do
      FeaturedRepresentative.create(work_id: '111111111', file_set_id: '222222222', kind: 'epub')
      ActiveFedora::SolrService.add([mono.to_h, epub.to_h])
      ActiveFedora::SolrService.commit
      allow(EPubPolicy).to receive(:new).and_return(policy)
      allow(policy).to receive(:show?).and_return(access)
      allow(Time).to receive(:now).and_return(now)
    end

    context 'when the press shares links' do
      let(:press) { create(:press, subdomain: 'blah', share_links: true) }

      it 'returns a share link with a valid JSON webtoken and logs the creation' do
        get :share_link, params: { id: '222222222' }
        expect(response).to have_http_status(:success)
        expect(response.body).to eq "http://test.host/epubs/222222222?share=#{JsonWebToken.encode(data: '222222222', exp: now.to_i + share_link_expiration_time)}"
        expect(ShareLinkLog.count).to eq 1
        expect(ShareLinkLog.last.action).to eq 'create'
      end

      context 'with a user with institutions' do
        let(:inst1) { create(:institution, identifier: 1, name: 'U of M') }
        let(:inst2) { create(:institution, identifier: 2, name: 'O of U') }

        before { allow_any_instance_of(described_class).to receive(:current_institutions).and_return([inst1, inst2]) }

        it 'logs the institutions' do
          get :share_link, params: { id: '222222222' }
          expect(response).to have_http_status(:success)
          expect(ShareLinkLog.count).to eq 1
          expect(ShareLinkLog.last.institution).to eq "U of M|O of U"
        end
      end
    end

    context 'when a press does not share links' do
      let(:press) { create(:press, subdomain: 'urg') }

      it 'returns nothing' do
        get :share_link, params: { id: '222222222' }
        expect(response).to have_http_status(:success)
        expect(response.body).to be_empty
        expect(ShareLinkLog.count).to eq 0
      end
    end
  end
end
