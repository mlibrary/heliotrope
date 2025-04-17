# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Accessibility Claims Tab" do
  let(:press) { create(:press) }
  let(:monograph_id) { '999999999' }
  let(:monograph_doc) do
    {
      has_model_ssim: ['Monograph'],
      id: monograph_id,
      title_tesim: ['Monograph Title'],
      file_set_ids_ssim: [epub_id],
      read_access_group_ssim: ['public'],
      visibility_ssi: 'open',
      suppressed_bsi: false,
      press_sim: press.subdomain
    }
  end

  let(:epub_id) { '000000000' }
  let(:epub_doc) do
    {
      id: epub_id,
      has_model_ssim: ['FileSet'],
      visibility_ssi: 'open'
    }
  end

  before do
    ActiveFedora::SolrService.add([monograph_doc, epub_doc])
    ActiveFedora::SolrService.commit
    FeaturedRepresentative.create(work_id: monograph_id, file_set_id: epub_id, kind: 'epub')
  end

  context '`Flipflop.show_accessibility_claims_tab?` returns the default value of `false`' do
    it 'does not show the tab' do
      visit monograph_catalog_path(id: monograph_id)
      expect(page).to_not have_selector('#tab-accessibility-claims')
      expect(page).to_not have_selector('#accessibility-claims')
      expect(page).to_not have_link('Request Accessible Copy')
    end
  end

  context '`Flipflop.show_accessibility_claims_tab?` returns `true`' do
    before { allow(Flipflop).to receive(:show_accessibility_claims_tab?).and_return(true) }

    it 'shows the tab with the "Request Accessible Copy" button' do
      visit monograph_catalog_path(id: monograph_id)
      expect(page).to have_selector('#tab-accessibility-claims')
      expect(page).to have_selector('#accessibility-claims')
      expect(page).to have_link('Request Accessible Copy')
    end

    context 'Monograph is protected, i.e. anonymous user is not authed to it' do
      let(:parent) { Sighrax.from_noid(monograph_id) }
      before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

      it 'shows the tab, but does not show the "Request Accessible Copy" button' do
        visit monograph_catalog_path(id: monograph_id)
        expect(page).to have_selector('#tab-accessibility-claims')
        expect(page).to have_selector('#accessibility-claims')
        expect(page).to_not have_link('Request Accessible Copy')
      end
    end
  end
end
