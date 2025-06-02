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
      press_tesim: [press.subdomain],
      epub_a11y_screen_reader_friendly_ssi: epub_a11y_screen_reader_friendly_ssi
    }
  end

  let(:epub_a11y_screen_reader_friendly_ssi) { nil }
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

  describe 'Flipflop.show_accessibility_claims_tab?' do
    context 'returns the default value of `false`' do
      it 'does not show the tab' do
        visit monograph_catalog_path(id: monograph_id)
        # 'Accessibility Claims' tab
        expect(page).to_not have_selector('#tab-accessibility-claims')
        expect(page).to_not have_selector('#accessibility-claims')
        # metadata block on the tab
        expect(page).to_not have_link('Request Accessible Copy')
      end
    end

    context 'returns `true`' do
      before { allow(Flipflop).to receive(:show_accessibility_claims_tab?).and_return(true) }

      it 'shows the tab with the "Request Accessible Copy" button' do
        visit monograph_catalog_path(id: monograph_id)
        # 'Accessibility Claims' tab
        expect(page).to have_selector('#tab-accessibility-claims')
        expect(page).to have_selector('#accessibility-claims')
        # metadata block on the tab
        expect(page).to have_link('Request Accessible Copy')
      end

      context 'Monograph is protected, i.e. anonymous user is not authed to it' do
        let(:parent) { Sighrax.from_noid(monograph_id) }
        before { Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid) }

        it 'shows the tab, but does not show the "Request Accessible Copy" button' do
          visit monograph_catalog_path(id: monograph_id)
          # 'Accessibility Claims' tab
          expect(page).to have_selector('#tab-accessibility-claims')
          expect(page).to have_selector('#accessibility-claims')
          # metadata block on the tab
          expect(page).to_not have_link('Request Accessible Copy')
        end
      end
    end
  end

  describe 'Press options' do
    before { allow(Flipflop).to receive(:show_accessibility_claims_tab?).and_return(true) }

    context 'show_accessibility_metadata' do
      # For the purposes of testing the effect of  the Press show_accessibility_metadata option, a minimal piece of...
      # metadata must be present to display. So this Monograph must be "screen-reader friendly", meaning
      # epub_a11y_screen_reader_friendly_ssi is indexed as 'yes'
      let(:epub_a11y_screen_reader_friendly_ssi) { 'yes' }

      context 'returns the default value of `true`' do
        it 'shows the metadata on the tab' do
          visit monograph_catalog_path(id: monograph_id)
          # 'Accessibility Claims' tab
          expect(page).to have_selector('#tab-accessibility-claims')
          expect(page).to have_selector('#accessibility-claims')
          # metadata block on the tab
          expect(page).to have_content 'Screen Reader Friendly: yes'
          # this is not present because the EPUB is "screen-reader friendly"
          expect(page).to_not have_link('Request Accessible Copy')
        end
      end

      context 'returns `false`' do
        let(:press) { create(:press, show_accessibility_metadata: false) }

        it 'shows the tab but does not show accessibility metadata' do
          visit monograph_catalog_path(id: monograph_id)
          # 'Accessibility Claims' tab
          expect(page).to have_selector('#tab-accessibility-claims')
          expect(page).to have_selector('#accessibility-claims')
          # metadata block on the tab
          expect(page).to_not have_content 'Screen Reader Friendly: yes'
          # this is not present because it sits inside the metadata section which is prevented from displaying (plus...
          # the EPUB is "screen-reader friendly" so it wouldn't show up anyway ;-)
          expect(page).to_not have_link('Request Accessible Copy')
        end
      end
    end

    context 'show_request_accessible_copy_button' do
      # For the purposes of testing the effect of show_request_accessible_copy_button, the metadata itself must be...
      # visible, given the fact that the 'Request Accessible Copy' button nests inside it.
      # Additionally, the EPUB must *not* have been indexed on the Monograph Solr doc as "screen-reader friendly",...
      # meaning epub_a11y_screen_reader_friendly_ssi is anything other than 'yes'
      let(:epub_a11y_screen_reader_friendly_ssi) { 'unknown' }

      context 'returns the default value of `true`' do
        it 'shows the "Request Accessible Copy" button on the tab' do
          visit monograph_catalog_path(id: monograph_id)
          # 'Accessibility Claims' tab
          expect(page).to have_selector('#tab-accessibility-claims')
          expect(page).to have_selector('#accessibility-claims')
          # metadata block on the tab
          expect(page).to have_content 'Screen Reader Friendly: No information is available'
          expect(page).to have_link('Request Accessible Copy')
        end
      end

      context 'returns `false`' do
        let(:press) { create(:press, show_request_accessible_copy_button: false) }

        it 'does not show the "Request Accessible Copy" button on the tab' do
          visit monograph_catalog_path(id: monograph_id)
          # 'Accessibility Claims' tab
          expect(page).to have_selector('#tab-accessibility-claims')
          expect(page).to have_selector('#accessibility-claims')
          # metadata block on the tab
          expect(page).to have_content 'Screen Reader Friendly: No information is available'
          # this is not present because it sits inside the metadata section which is prevented from displaying (plus...
          # the EPUB is "screen-reader friendly" so it wouldn't show up anyway ;-)
          expect(page).to_not have_link('Request Accessible Copy')
        end
      end
    end
  end
end
