# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Catalog TOC", type: :system, browser: true do
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, press: press.subdomain, user: User.batch_user, visibility: "open", representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) { create(:file_set, id: '999999999', visibility: "open", keyword: ['one', 'two', 'three', 'four', 'five', 'six'], content: File.open(File.join(fixture_path, 'csv', 'shipwreck.jpg'))) }

  before do
    stub_out_redis
    monograph.ordered_members << cover
    monograph.save!
    cover.save!
  end

  # Comment this method out to see screenshots on failures in tmp/screenshots
  def take_failed_screenshot
    false
  end

  context 'Using the full-screen cover image Bootstrap modal' do
    it 'works as expected' do
      visit monograph_catalog_path(monograph)
      expect(page).to have_css("body.#{press.subdomain}")
      expect(page).not_to have_css("body.#{press.subdomain}.modal-open")
      expect(page).to have_css("div#modalImage", visible: false)

      # click the Monograph thumbnail
      find("button[data-target='#modalImage'").click
      expect(page).to have_css("body.#{press.subdomain}.modal-open")
      expect(page).to have_css("div#modalImage", visible: true)

      # For fun, we'll hit 'Escape' to close the modal (there is a hard-to-see 'x' button also)
      input = find("div#modalImage").native
      input.send_key(:escape)
      expect(page).to have_css("body.#{press.subdomain}")
      expect(page).not_to have_css("body.#{press.subdomain}.modal-open")
      expect(page).to have_css("div#modalImage", visible: false)
    end
  end

  context 'Using the Blacklight facet "more" Bootstrap modal' do
    before do
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    it 'works as expected, adds a11y-relevant `hidden` attributes' do
      visit monograph_catalog_path(monograph)

      # expand facet modal
      find("div[data-target='#facet-keyword_sim'").click
      expect(page).to have_css("a[data-ga-event-action='facet_keyword']", count: 5)

      # `blacklight_modal_a11y_additions.js` actually sticks `hidden` on all children of <body> - script tags, cookie consent n'all - but...
      # that's too egregious to test, especially with Capybara's own perceived visibility in play. FYI, the cookie...
      # consent div can actually be visible with "hidden" applied to it. Just verify the main div is behaving as expected.
      expect(page).to have_css("div#main", visible: true)
      expect(page).not_to have_css("div#main[hidden='hidden']", visible: true) # verify lack of `hidden` attribute
      expect(page).to have_css("div#blacklight-modal[hidden='hidden']", visible: false)

      # somehow this expect gets the find afterwards to work more consistently. Bah. Timing errors.
      expect(page).to have_css("div#facet-keyword_sim a.more_facets_link")
      # click "more" link to open full-screen facet modal overlay
      find("a[href='#{monograph_catalog_facet_path(id: 'keyword_sim', monograph_id: monograph.id, locale: 'en')}']").click
      expect(page).to have_css("div#main[hidden='hidden']", visible: false)
      expect(page).to have_css("div#blacklight-modal", visible: true)
      expect(page).not_to have_css("div#blacklight-modal[hidden='hidden']", visible: true) # verify lack of `hidden` attribute

      # close out the full-screen facet modal
      find("button.blacklight-modal-close").click
      expect(page).to have_css("div#main", visible: true)
      expect(page).not_to have_css("div#main[hidden='hidden']", visible: true) # verify lack of `hidden` attribute
      expect(page).to have_css("div#blacklight-modal[hidden='hidden']", visible: false)
    end
  end
end
