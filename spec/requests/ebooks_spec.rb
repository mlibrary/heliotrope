# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PDF EBooks", type: :request do
  describe "GET /ebooks/:id/download" do
    subject { get download_ebook_path(noid) }

    let(:noid) { 'validnoid' }
    let(:ebook) { instance_double(Sighrax::Ebook, 'ebook', noid: noid, data: {}, valid?: true, title: 'title', watermarkable?: watermarkable, publisher: publisher) }
    let(:watermarkable) { false }
    let(:publisher) { instance_double(Sighrax::Publisher, 'publihser', watermark?: watermark) }
    let(:watermark) { false }
    let(:ebook_download_op) { instance_double(EbookDownloadOperation, 'ebook_download_op', allowed?: allowed) }
    let(:allowed) { false }

    before do
      allow(Sighrax).to receive(:from_noid).with(noid).and_return(ebook)
      allow(EbookDownloadOperation).to receive(:new).with(anything, ebook).and_return ebook_download_op
    end

    it do
      expect { subject }.not_to raise_error
      expect(response).to have_http_status(:unauthorized)
      expect(response).to render_template('hyrax/base/unauthorized')
    end

    context 'allowed?' do
      let(:allowed) { true }

      it do
        expect { subject }.not_to raise_error
        expect(response).to have_http_status(:found)
        expect(response).to redirect_to(hyrax.download_path(noid))
      end

      context 'watermarkable?' do
        let(:watermarkable) { true }

        it do
          expect { subject }.not_to raise_error
          expect(response).to have_http_status(:found)
          expect(response).to redirect_to(hyrax.download_path(noid))
        end

        describe 'watermark' do
          let(:watermark) { true }
          let(:ebook) do
            instance_double(
              Sighrax::Ebook, 'ebook',
              noid: noid,
              data: {},
              valid?: true,
              parent: parent,
              title: 'title',
              resource_token: 'resource_token',
              media_type: 'application/pdf',
              filename: 'clippath.pdf',
              watermarkable?: watermarkable,
              publisher: publisher
            )
          end
          let(:parent) { instance_double(Sighrax::Ebook, title: 'title') }
          let(:ebook_presenter) { double("ebook_presenter") }
          let(:counter_service) { double("counter_service") }

          before do
            allow(ebook).to receive(:content).and_return(File.read(Rails.root.join(fixture_path, ebook.filename)))
            allow(Sighrax).to receive(:hyrax_presenter).with(ebook).and_return(ebook_presenter)
            allow(CounterService).to receive(:from).and_return(counter_service)
            allow(counter_service).to receive(:count).with(request: 1).and_return(true)
          end

          context 'presenter returns an authors value' do
            let(:presenter) do
              instance_double(Hyrax::MonographPresenter, authors?: true,
                                                         authors: 'creator blah',
                                                         creator: ['Creator, A.', 'Destroyer, Z.'],
                                                         title: 'title',
                                                         date_created: ['created'],
                                                         based_near_label: ['Somewhere'],
                                                         citable_link: 'www.example.com/something',
                                                         publisher: ['publisher'])
            end

            it 'uses it in the watermark' do
              allow(Sighrax).to receive(:hyrax_presenter).with(parent).and_return(presenter)
              expect { subject }.not_to raise_error
              expect(response).to have_http_status(:ok)
              expect(response.body).not_to be_empty
              # watermarking will change the file content and PDF 'producer' metadata
              expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, ebook.filename))
              expect(response.body).to include('Producer (Ruby CombinePDF')
              expect(response.header['Content-Type']).to eq(ebook.media_type)
              expect(response.header['Content-Disposition']).to eq("attachment; filename=\"#{ebook.filename}\"")
              expect(counter_service).to have_received(:count).with(request: 1)
            end
          end

          context 'presenter does not return an authors value' do
            let(:presenter) { instance_double(Hyrax::MonographPresenter, authors?: false,
                                                                         creator: [],
                                                                         title: 'title',
                                                                         date_created: ['created'],
                                                                         based_near_label: ['Somewhere'],
                                                                         citable_link: 'www.example.com/something',
                                                                         publisher: ['publisher']) }

            it "doesn't raise an error" do
              allow(Sighrax).to receive(:hyrax_presenter).with(parent).and_return(presenter)
              expect { subject }.not_to raise_error
              expect(response).to have_http_status(:ok)
              expect(response.body).not_to be_empty
              expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, ebook.filename))
              expect(response.header['Content-Type']).to eq(ebook.media_type)
              expect(response.header['Content-Disposition']).to eq("attachment; filename=\"#{ebook.filename}\"")
              expect(counter_service).to have_received(:count).with(request: 1)
            end
          end
        end
      end
    end
  end
end
