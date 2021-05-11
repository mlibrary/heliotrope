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
              filename: 'lorum_ipsum_toc.pdf',
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
            allow(Sighrax).to receive(:hyrax_presenter).with(parent).and_return(presenter)
            allow(CounterService).to receive(:from).and_return(counter_service)
            allow(counter_service).to receive(:count).with(request: 1).and_return(true)
          end

          context 'presenter missing citation metadata needed for cover page' do
            let(:presenter) do
              instance_double(Hyrax::MonographPresenter, id: 'validnoid', citations_ready?: false)
            end

            it 'does not serve a PDF' do
              expect { subject }.not_to raise_error
              expect(assigns(:entity))
              expect(response).to have_http_status(:success)
              expect(response).to have_http_status(:no_content)
              expect(response.body).to be_empty
              expect(response.header['Content-Type']).to eq nil
              expect(response.header['Content-Disposition']).to eq nil
              expect(counter_service).to_not have_received(:count)
            end
          end

          context 'presenter has all citation metadata needed for cover page' do
            let(:presenter) { instance_double(Hyrax::MonographPresenter, authors?: true,
                                                                         authors: 'asdfasdfsa',
                                              citations_ready?: true,
                                              epub?: false,
                                              pdf_ebook?: true,

                                                                         copyright_holder: 'asdfasdf',
                                                                         creator: ['Doe, A. Deer'],
                                                                         title: 'title',
                                                                         date_created: ['created'],
                                                                         based_near_label: ['Somewhere'],
                                                                         citable_link: 'www.example.com/something',
                                                                         publisher: ['publisher']) }

            before { allow(ebook).to receive_message_chain(:parent, :publisher, :press, :logo_path, :file).and_return(nil) }

            it "serves a PDF with cover page" do
              expect { subject }.not_to raise_error
              expect(assigns(:entity))
              expect(response).to have_http_status(:success)
              expect(response).to have_http_status(:ok)
              expect(response.header['Content-Type']).to eq('application/pdf')
              expect(response.header['Content-Disposition']).to eq("attachment; filename=\"#{ebook.filename}\"")
              expect(response.headers['Content-Transfer-Encoding']).to eq 'binary'
              expect(response.body).not_to be_empty
              # watermarking will change the file content and PDF 'producer'/'keywords' metadata
              expect(response.body).not_to eq File.read(Rails.root.join(fixture_path, ebook.filename))
              expect(CombinePDF.parse(response.body, allow_optional_content: true).pages.count)
                  .to eq (CombinePDF.parse(File.read(Rails.root.join(fixture_path, ebook.filename), allow_optional_content: true)).pages.count + 1)
              expect(response.body).to include('Producer (Ruby CombinePDF')
              expect(response.body).to include('Keywords <feff') # BOM of UTF-16 encoded keywords string
              expect(counter_service).to have_received(:count).with(request: 1)
            end
          end
        end
      end
    end
  end
end
