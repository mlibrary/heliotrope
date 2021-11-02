# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "URL fragment as param", type: :request do
  # let (:locale) { { locale: 'en' } }
  # let(:anything) { locale.merge({ anything: 'wayfless' }) }
  let(:anything) { { anything: 'wayfless' } }

  context 'EPub Show' do
    subject { get epub_path(epub.id), params: params }

    let(:monograph) { create(:public_monograph, press: press.subdomain) }
    let(:press) { create(:press) }
    let(:cover) { create(:public_file_set) }
    let(:epub) { create(:public_file_set, allow_download: 'yes') }
    let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }
    let(:params) { anything }

    before do
      monograph.ordered_members << cover
      monograph.representative_id = cover.id
      monograph.ordered_members << epub
      monograph.save!
      cover.save!
      epub.save!
      fr
    end

    it do
      subject
      expect(response).to have_http_status(:ok)
      expect(response).to render_template(:show)
    end

    context 'when hash param' do
      let(:params) { anything.merge(hash) }
      let(:hash) { { hash: 'fragment' } }

      it do
        subject
        expect(response).to redirect_to(epub_path(epub.id, params: anything) + '#' + hash[:hash])
      end
    end
  end
end
