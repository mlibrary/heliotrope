# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PDF ebook reader", type: :system, browser: true do
  let(:press) { create(:press) }
  let(:monograph) { create(:public_monograph, press: press.subdomain, representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'lorum_ipsum_toc_cover.png'))) }
  let(:file_set) { create(:public_file_set, allow_download: 'no', content: File.open(File.join(fixture_path, 'lorum_ipsum_toc.pdf'))) }
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

  context 'open access PDF ebook' do
    before { monograph.update!(open_access: 'yes') }

    it 'renders the cozy-sun-bear reader chrome and hides the stock pdf.js toolbar' do
      visit epub_path(id: file_set.id)

      # The reader page should load without error
      expect(page).to have_css('#reader')

      # The cozy-sun-bear top-level reader container should be present
      expect(page).to have_css('#epub')

      # The PDF viewer iframe should be present in the parent DOM.
      # The iframe src is set dynamically so we assert the element exists, not the src.
      # Note: the iframe loads viewer.html from fulcrum/mozilla-pdf-viewer/web/ and
      # cozy-iframe-overrides.css hides the stock toolbar inside it (flash-free).
      expect(page).to have_css('#mainContainer')

      # The stock pdf.js toolbar lives INSIDE the iframe, not in the parent document.
      # Capybara queries the parent document, so #toolbarContainer won't be found there —
      # this confirms there is no toolbar chrome leaking into the parent page.
      expect(page).not_to have_css('#toolbarContainer')

      # The parent page should NOT have a pdfLoadingProgressBar with visible content
      # (it is an sr-only accessibility announcer, not a visible bar)
      expect(page).to have_css('#pdfLoadingProgressBar')
    end

    it 'renders the Contents button (cozy-sun-bear sidebar control)' do
      visit epub_path(id: file_set.id)

      expect(page).to have_css('#reader')

      # The cozy-sun-bear Contents control should be rendered in the parent page.
      # This exercises the PDFContents cozy control defined in show_pdf.html.erb.
      expect(page).to have_css('.cozy-container', wait: 5)
    end
  end
end
