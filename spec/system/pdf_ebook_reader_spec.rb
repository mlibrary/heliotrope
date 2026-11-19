# frozen_string_literal: true

require 'rails_helper'

# System spec for the iframe-based PDF ebook reader (pdf.js 6.5.438).
# Checks that:
#   - The cozy-sun-bear chrome renders on the parent page
#   - The stock pdf.js toolbar is NOT visible (hidden by cozy-iframe-overrides.css inside the iframe)
#   - Both reader styles pass a cache-busted PDF file URL to the viewer iframe
#   - Basic page navigation controls are available
#   - The vendored module loads and renders a PDF page in both reader layouts
#
# NOTE: Full headless rendering (PDF pages painted inside the iframe) is impractical in CI
# because the browser cannot serve range-requests to itself in the test environment.
# These specs assert the parent-side cozy chrome and iframe presence; deep pdf.js internals
# (actual page rendering, search results) require manual functional testing.

RSpec.describe "PDF Ebook Reader", type: :system, browser: true do
  let(:press) { create(:press) }
  let(:monograph) { create(:public_monograph, press: press.subdomain, representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) do
    create(:public_file_set,
           id: '999999990',
           allow_download: 'no',
           content: File.open(File.join(fixture_path, 'lorum_ipsum_toc.pdf')))
  end
  let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'pdf_ebook') }

  before do
    stub_out_redis
    monograph.ordered_members << cover
    monograph.ordered_members << file_set
    monograph.save!
    cover.save!
    file_set.save!
    UnpackJob.perform_now(file_set.id, 'pdf_ebook')
    fr
  end

  # Comment this method out to see screenshots on failures in tmp/screenshots
  def take_failed_screenshot
    false
  end

  shared_examples 'public OA monograph with pdf_ebook' do
    it 'renders the cozy-sun-bear reader chrome on the parent page' do
      visit epub_path(id: file_set.id)

      # The cozy-sun-bear reader container should be present on the parent page
      expect(page).to have_css('#reader')
      expect(page).to have_css('#epub')
    end

    [true, false].each do |use_new_reader|
      it "embeds the pdf.js viewer with a cache-busted file URL in the #{use_new_reader ? 'new' : 'old'} reader" do
        allow(Flipflop).to receive(:use_new_reader_style_wherever_possible?).and_return(use_new_reader)
        allow_any_instance_of(Hyrax::FileSetPresenter).to receive(:browser_cache_breaker).and_return('1700000000')

        visit epub_path(id: file_set.id)

        iframe = find('iframe#pdf-viewer-iframe', visible: :all)
        viewer_url = URI.parse(iframe[:src])
        expect(viewer_url.path).to eq('/pdfjs-6.5.438/web/viewer.html')

        viewer_params = URI.decode_www_form(viewer_url.query).to_h
        expected_file_url = URI.join(page.current_url, "/epubs/#{file_set.id}/file?1700000000").to_s
        expect(viewer_params.fetch('file')).to eq(expected_file_url)
      end
    end

    it 'loads the vendored PDF module and hides its stock chrome inside the iframe' do
      visit epub_path(id: file_set.id)

      within_frame('pdf-viewer-iframe') do
        expect(page).to have_css('#viewer .page canvas', wait: 30)
        expect(page.evaluate_script('window.pdfjsLib.version')).to eq('6.5.438')
        expect(page).to have_css('link[href="cozy-iframe-overrides.css"]', visible: :all)
        expect(page).to have_css('#outerContainer .toolbar', visible: :hidden)
        expect(page).to have_css('#viewsManager', visible: :hidden)
      end
    end

    it 'finds PDF text through the parent search controls' do
      visit epub_path(id: file_set.id)

      expect(page).to have_css('#cozy-search-string', visible: :all)
      find('button[aria-label="Search"]', match: :first).click
      fill_in 'Search in this text', with: 'ipsum'
      find('.cozy-search button[type="submit"]').click

      expect(page).to have_css('a.search-result', text: /ipsum/i)
    end

    it 'copies the outline and renders clickable page thumbnails' do
      visit epub_path(id: file_set.id)

      expect(page).to have_css('#cozy-search-string', visible: :all)
      within_frame('pdf-viewer-iframe') do
        expect(page).to have_css('#outlinesView a', visible: :all)
      end
      find('#sidebarToggle').click
      expect(page).to have_css('#outlineView a')
      click_button 'Page List'
      expect(page).to have_css('#thumbnailView .thumbnail[page-number="2"] img[src^="data:image/jpeg"]')
      find('#thumbnailView .thumbnail[page-number="2"]').click

      within_frame('pdf-viewer-iframe') do
        expect(page.evaluate_script('window.PDFViewerApplication.page')).to eq(2)
      end
    end

    it 'does not render the stock pdf.js toolbar in the parent page' do
      visit epub_path(id: file_set.id)

      # The stock pdf.js toolbar lives inside the iframe (and is hidden by cozy-iframe-overrides.css).
      # It must NOT appear as a direct child of the parent document.
      expect(page).not_to have_css('#toolbarContainer', visible: :visible)
      expect(page).not_to have_css('#toolbarViewer', visible: :visible)
    end

    it 'has the aria live region for loading progress on the parent page' do
      visit epub_path(id: file_set.id)

      # #pdfLoadingProgressBar is the parent-side screen-reader announcer
      expect(page).to have_css('#pdfLoadingProgressBar')
    end
  end

  context 'with the new reader layout' do
    before { allow(Flipflop).to receive(:use_new_reader_style_wherever_possible?).and_return(true) }

    it_behaves_like 'public OA monograph with pdf_ebook'
  end

  context 'with the old reader layout' do
    before { allow(Flipflop).to receive(:use_new_reader_style_wherever_possible?).and_return(false) }

    it_behaves_like 'public OA monograph with pdf_ebook'
  end
end
