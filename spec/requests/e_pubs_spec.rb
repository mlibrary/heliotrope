# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "EPubs", type: :request do
  let(:monograph) {
    create(:public_monograph,
           user: user,
           press: press.subdomain,
           creator: ['Doe, A. Deer'], # all citation metadata is needed for PDF cover page
           date_created: ['2003'],
           location: 'Collegeville, MN',
           publisher: ['Uni Press'],
           representative_id: cover.id,
           thumbnail_id: thumbnail.id)
  }
  let(:user) { create(:user) }
  let(:press) { create(:press) }
  let(:cover) { create(:public_file_set) }
  let(:thumbnail) { create(:public_file_set) }
  let(:epub) { create(:public_file_set) }
  let(:publication) { EPub::Publication.null_object }
  let(:counter_service) { double("counter_service") }

  before do
    monograph.ordered_members = [cover, thumbnail, epub]
    monograph.save!
    [cover, thumbnail, epub].map(&:save!)
    allow(EPub::Publication).to receive(:from_directory).with(UnpackService.root_path_from_noid(epub.id, 'epub')).and_return(publication)
    allow(CounterService).to receive(:from).and_return(counter_service)
  end

  context 'Invalid noid' do
    describe 'GET /epubs/:id' do
      subject { get "/epubs/default.css" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:not_found)
        expect(response.body).to match("404 - The page you were looking for doesn't exist")
      end
    end
  end

  context 'Electronic Publication' do
    describe 'GET /epubs/:id' do
      subject { get "/epubs/#{epub.id}" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template('hyrax/base/unauthorized')
      end
    end

    describe 'GET /epubs/:id/*file' do
      subject { get "/epubs/#{epub.id}/META-INF/container.xml" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response.body).to be_empty
      end
    end

    describe 'GET /epubs_download_chapter/:id' do
      subject { get "/epubs_download_chapter/#{epub.id}" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template('hyrax/base/unauthorized')
      end
    end

    describe 'GET /epubs_download_interval/:id' do
      subject { get "/epubs_download_interval/#{epub.id}" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template('hyrax/base/unauthorized')
      end
    end

    describe 'GET /epubs_search/:id' do
      subject { get "/epubs_search/#{epub.id}" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template('hyrax/base/unauthorized')
      end
    end

    describe 'GET /epubs_share_link/:id' do
      subject { get "/epubs_share_link/#{epub.id}" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:unauthorized)
        expect(response).to render_template('hyrax/base/unauthorized')
      end
    end
  end

  context 'Featured Electronic Publication' do
    let(:fre) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:policy) { double('policy') }

    before do
      fre
      allow(EPubPolicy).to receive(:new).and_return(policy)
      allow(policy).to receive(:show?).and_return(access)
    end

    context 'unauthorized' do
      let(:access) { false }

      describe 'GET /epubs/:id' do
        subject { get "/epubs/#{epub.id}" }

        before do
          Greensub::Institution.create!(identifier: Settings.world_institution_identifier, name: "Unknown Insitution", display_name: "Unknown Institution")
          allow_any_instance_of(CounterService).to receive(:robot?).and_return(false)
        end

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(monograph_authentication_url(monograph.id))
          expect(CounterReport.first.turnaway).to eq "No_License"
        end
      end

      describe 'GET /epubs/:id/*file' do
        subject { get "/epubs/#{epub.id}/META-INF/container.xml" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end

      describe 'GET /epubs_download_chapter/:id' do
        subject { get "/epubs_download_chapter/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end

      describe 'GET /epubs_download_interval/:id' do
        subject { get "/epubs_download_interval/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end

      describe 'GET /epubs_search/:id' do
        subject { get "/epubs_search/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:not_found)
          expect(response.body).to be_empty
        end
      end

      describe 'GET /epubs_share_link/:id' do
        subject { get "/epubs_share_link/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end
    end

    context 'authorized' do
      let(:access) { true }

      describe "GET /epubs/:id" do
        subject { get "/epubs/#{epub.id}" }

        before { allow(counter_service).to receive(:count).with(request: 1) }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:ok)
          expect(response).to render_template(:show)
          expect(counter_service).to have_received(:count).with(request: 1)
        end
      end

      describe 'GET /epubs/:id/*file' do
        subject { get "/epubs/#{epub.id}/present.txt" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end

        context 'present' do
          before { allow(publication).to receive(:file).with('present.txt').and_return(File.join(fixture_path, 'present.txt')) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to have_http_status(:ok)
            expect(response.body).to eq('present')
          end
        end
      end

      describe 'GET /epubs_download_chapter/:id' do
        subject { get "/epubs_download_chapter/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end

        context 'cfi' do
          subject { get "/epubs_download_chapter/#{epub.id}?cfi=cfi" }

          let(:chapter) { double('chapter', title: 'title', pdf: pdf) }
          let(:pdf) { double('pdf', render: rendered_pdf) }
          let(:rendered_pdf) { 'rendered_pdf' }

          before do
            allow(EPub::Chapter).to receive(:from_cfi).with(publication, 'cfi').and_return(chapter)
            allow(counter_service).to receive(:count).with(request: 1, section: 'title', section_type: 'Chapter')
          end

          it do
            expect { subject }.not_to raise_error
            expect(response).to have_http_status(:ok)
            expect(response.body).to eq(rendered_pdf)
            expect(counter_service).to have_received(:count).with(request: 1, section: 'title', section_type: 'Chapter')
          end
        end
      end

      describe 'GET /epubs_download_interval/:id' do
        subject { get "/epubs_download_interval/#{epub.id}" }

        let(:ebook_interval_download_op) { instance_double(EbookIntervalDownloadOperation, 'ebook_interval_download_op', allowed?: true) }

        before do
          allow(EbookIntervalDownloadOperation).to receive(:new).with(anything, Sighrax.from_noid(epub.id)).and_return ebook_interval_download_op
        end

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end

        context 'chapter download' do
          subject { get "/epubs_download_interval/#{epub.id}?title=title;chapter_index=0" }

          before do
            allow(UnpackService).to receive(:root_path_from_noid).and_return(fixture_path)
            allow(counter_service).to receive(:count).with(request: 1, section: 'title', section_type: 'Chapter')
          end

          it do
            expect { subject }.not_to raise_error
            expect(response).to have_http_status(:ok)
            # watermarking will change the file content and add fonts
            expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, '0.pdf'))
            expect(response.body).to include('OpenSans-Regular')
            expect(response.body).to include('OpenSans-Italic')
            expect(counter_service).to have_received(:count).with(request: 1, section: 'title', section_type: 'Chapter')
          end
        end
      end

      describe 'GET /epubs_download_interval/:id with a FeaturedRepresentative of kind pdf_ebook' do
        subject { get "/epubs_download_interval/#{epub.id}" }

        let(:fre) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'pdf_ebook') }
        let(:ebook_interval_download_op) { instance_double(EbookIntervalDownloadOperation, 'ebook_interval_download_op', allowed?: true) }

        before do
          allow(EbookIntervalDownloadOperation).to receive(:new).with(anything, Sighrax.from_noid(epub.id)).and_return ebook_interval_download_op
        end

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end

        context 'chapter download' do
          subject { get "/epubs_download_interval/#{epub.id}?title=title;chapter_index=0" }

          before do
            allow(UnpackService).to receive(:root_path_from_noid).and_return(fixture_path)
            allow(counter_service).to receive(:count).with(request: 1, section: 'title', section_type: 'Chapter')
          end

          it do
            expect { subject }.not_to raise_error
            expect(response).to have_http_status(:ok)
            # watermarking will change the file content and add fonts
            expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, '0.pdf'))
            expect(response.body).to include('OpenSans-Regular')
            expect(response.body).to include('OpenSans-Italic')
            expect(counter_service).to have_received(:count).with(request: 1, section: 'title', section_type: 'Chapter')
          end
        end
      end

      describe 'GET /epubs_search/:id' do
        subject { get "/epubs_search/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:ok)
          body = JSON.parse(response.body)
          expect(body['q']).to eq('')
          expect(body['search_results'].length).to eq(0)
        end

        context '12' do
          subject { get "/epubs_search/#{epub.id}?q=12" }

          it do
            expect { subject }.not_to raise_error
            expect(response).to have_http_status(:ok)
            body = JSON.parse(response.body)
            expect(body['q']).to eq('12')
            expect(body['search_results'].length).to eq(0)
          end
        end

        context 'query' do
          subject { get "/epubs_search/#{epub.id}?q=query" }

          let(:results) { { 'q': 'query', 'search_results': ['results'] } }

          before { allow(publication).to receive(:search).with('query').and_return(results) }

          it do
            expect { subject }.not_to raise_error
            expect(response).to have_http_status(:ok)
            body = JSON.parse(response.body)
            expect(body['q']).to eq('query')
            expect(body['search_results']).to eq(['results'])
          end
        end
      end

      describe 'GET /epubs_share_link/:id' do
        subject { get "/epubs_share_link/#{epub.id}" }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:no_content)
          expect(response.body).to be_empty
        end
      end

      context "log share link use" do
        describe "GET /epubs/:id" do
          subject { get "/epubs/#{epub.id}?share=#{token}" }

          before { allow(counter_service).to receive(:count).with(request: 1) }

          context "expired token" do
            let(:token) { JsonWebToken.encode(data: epub.id, exp: Time.now.to_i - 1000) }

            it do
              expect { subject }.not_to raise_error
              expect(response).to have_http_status(:ok)
              expect(response).to render_template(:show)
              expect(counter_service).to have_received(:count).with(request: 1)
            end
          end

          context "valid token" do
            let(:token) { JsonWebToken.encode(data: epub.id, exp: Time.now.to_i + 48 * 3600) }
            let(:request_attributes_for) { double('request_attributes_for') }
            let(:request_attributes) { { dlpsInstitutionId: [dlps_institution_id] } }
            let(:institution) { create(:institution, identifier: dlps_institution_id.to_s, entity_id: 'https://entity.id') }
            let(:institution_affiliation) { create(:institution_affiliation, institution: institution, dlps_institution_id: dlps_institution_id, affiliation: 'member') }
            let(:dlps_institution_id) { 9999 }

            before do
              institution_affiliation
              allow(Services).to receive(:request_attributes).and_return(request_attributes_for)
              allow(request_attributes_for).to receive(:for).and_return(request_attributes)
              allow(ShareLinkLog).to receive(:create)
            end

            it do
              expect { subject }.not_to raise_error
              expect(response).to have_http_status(:ok)
              expect(response).to render_template(:show)
              expect(counter_service).to have_received(:count).with(request: 1)
              expect(ShareLinkLog).to have_received(:create).with(
                ip_address: request.ip,
                institution: institution.name,
                press: press.subdomain,
                title: monograph.title.first,
                noid: epub.id,
                token: token,
                action: 'use'
              )
            end
          end
        end
      end
    end
  end

  context 'Princesse De Cleves' do
    describe 'GET /epubs/pdecleves' do
      subject { get "/epubs/pdecleves" }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(epub_ebook_path('pdecleves'))
      end
    end
  end
end
