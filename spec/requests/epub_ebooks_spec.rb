# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Epub Ebooks", type: :request do
  context 'Princesse De Cleves' do
    let(:monograph) {
      create(:public_monograph,
             user: user,
             press: press.subdomain,
             representative_id: cover.id,
             thumbnail_id: thumbnail.id)
    }
    let(:user) { create(:user) }
    let(:press) { create(:press) }
    let(:cover) { create(:public_file_set) }
    let(:thumbnail) { create(:public_file_set) }
    let(:epub) { create(:public_file_set, id: 'pdecleves') }
    let(:publication) { EPub::Publication.null_object }
    let(:counter_service) { double('counter_service') }
    let(:fre) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:ebook_reader_op) { instance_double(EbookReaderOperation, 'ebook_reader_op', allowed?: allowed) }

    before do
      monograph.ordered_members = [cover, thumbnail, epub]
      [monograph, cover, thumbnail, epub].map(&:save!)
      fre
      allow(EbookReaderOperation).to receive(:new).and_return ebook_reader_op
      allow(EPub::Publication).to receive(:from_directory).with(UnpackService.root_path_from_noid(epub.id, 'epub')).and_return publication
      allow(CounterService).to receive(:from).and_return counter_service
      allow(counter_service).to receive(:count).with(request: 1)
    end

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
end
