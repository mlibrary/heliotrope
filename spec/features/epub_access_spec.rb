# frozen_string_literal: true

require 'rails_helper'

describe 'Access Page' do
  context 'restricted access page for protected ebooks' do
    let(:press) { create(:press) }
    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
    let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }
    let(:epub) { Sighrax.from_noid(file_set.id) }

    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
      fr
    end

    after { FeaturedRepresentative.destroy_all }

    context 'generic message' do
      it 'shows the message' do
        visit monograph_authentication_url(monograph.id)
        expect(page).to have_http_status(:success)
      end
    end

    context 'custom message' do
      let(:press) { create(:press, subdomain: subdomain, restricted_message: '<b>No. Just No.</b>') }

      context 'in michigan press' do
        let(:subdomain) { 'michigan' }

        it 'shows the message' do
          visit monograph_authentication_url(monograph.id)
          expect(page).to have_http_status(:success)
        end
      end

      context 'in heb press' do
        let(:subdomain) { 'heb' }

        it 'shows the message' do
          visit monograph_authentication_url(monograph.id)
          expect(page).to have_http_status(:success)
        end
      end

      context 'in barpublishing press' do
        let(:subdomain) { 'barpublishing' }

        it 'shows the message' do
          visit monograph_authentication_url(monograph.id)
          expect(page).to have_http_status(:success)
        end
      end
    end
  end
end
