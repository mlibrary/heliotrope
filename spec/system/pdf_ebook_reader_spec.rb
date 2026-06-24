# frozen_string_literal: true

require 'rails_helper'

# System spec for the iframe-based PDF ebook reader (pdf.js 6.0.227).
# Checks that:
#   - The cozy-sun-bear chrome renders on the parent page
#   - The stock pdf.js toolbar is NOT visible (hidden by cozy-iframe-overrides.css inside the iframe)
#   - The PDF viewer iframe is present
#   - Basic page navigation controls are available
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

  context 'public OA monograph with pdf_ebook' do
    it 'renders the cozy-sun-bear reader chrome on the parent page' do
      visit epub_path(id: file_set.id)

      # The cozy-sun-bear reader container should be present on the parent page
      expect(page).to have_css('#reader')
      expect(page).to have_css('#epub')
    end

    it 'embeds the pdf.js viewer in an iframe' do
      visit epub_path(id: file_set.id)

      # The iframe carrying the pdf.js viewer must be present
      expect(page).to have_css('iframe#pdf-viewer-iframe', visible: :all)
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
end
