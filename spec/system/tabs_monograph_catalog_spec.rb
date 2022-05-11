# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Monograph Bootstrap tabs", type: :system, browser: true do
  let(:press) { create(:press) }
  let(:monograph) { create(:monograph, press: press.subdomain, user: User.batch_user, visibility: "open", representative_id: cover.id) }
  let(:cover) { create(:file_set, visibility: "open", content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) { create(:file_set, visibility: "open", keywords: ['one'], content: File.open(File.join(fixture_path, 'csv', 'shipwreck.jpg'))) }
  let(:epub) { create(:file_set, visibility: "open", allow_download: 'no', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
  let(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: epub.id, kind: 'epub') }

  before do
    stub_out_redis
    monograph.ordered_members = [cover, epub, file_set]
    monograph.save!
    cover.save!
    file_set.save!
    epub.save!
    UnpackJob.perform_now(epub.id, 'epub')
    fr
  end

  # Comment this method out to see screenshots on failures in tmp/screenshots
  # def take_failed_screenshot
  #   false
  # end

  context 'Monograph catalog page (with EPUB and resource FileSet)' do
    it 'has manual tab navigation that works as expected' do
      visit monograph_catalog_path(monograph)

      # toc tab link
      expect(page).to have_css("li.active h2 a#tab-toc")
      expect(page).to have_css("a#tab-toc[aria-selected=true][aria-expanded=true]")
      expect(page).to_not have_css("a#tab-toc[aria-selected=false][aria-expanded=false]")
      expect(page).to_not have_css("a#tab-toc[tabindex='-1']")
      # toc tab panel
      expect(page).to have_css("section#toc[aria-hidden=false]")
      expect(page).to_not have_css("section#toc[aria-hidden=true]", visible: false)

      # stats tab link
      # expect(page).to_not have_css("li.active h2 a#tab-stats")
      # expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
      # expect(page).to have_css("a#tab-stats[tabindex='-1']")
      # stats tab panel
      # expect(page).to_not have_css("section#stats[aria-hidden=false]")
      # expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

      visit monograph_catalog_path(monograph)

      # click stats tab
      # find("#tab-stats").click

      # stats tab link
      # expect(page).to have_css("li.active h2 a#tab-stats")
      # expect(page).to have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
      # expect(page).to_not have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
      # expect(page).to_not have_css("a#tab-stats[tabindex='-1']")
      # stats tab panel
      # expect(page).to have_css("section#stats[aria-hidden=false]")
      # expect(page).to_not have_css("section#stats[aria-hidden=true]", visible: false)

      # toc tab link
      # expect(page).to_not have_css("li.active h2 a#tab-toc")
      # expect(page).to_not have_css("a#tab-toc[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-toc[aria-selected=false][aria-expanded=false]")
      # expect(page).to have_css("a#tab-toc[tabindex='-1']")
      # toc tab panel
      # expect(page).to_not have_css("section#toc[aria-hidden=false]")
      # expect(page).to have_css("section#toc[aria-hidden=true]", visible: false)
    end

    it 'has Blacklight resources searching that opens the resources tab' do
      visit monograph_catalog_path(monograph)

      fill_in("Search resources", with: "shipwreck")
      find("#resources-search-submit").click

      # clear last search
      find("span.glyphicon.glyphicon-remove").click

      # test facet search
      # open the facet panel
      find("div[data-target='#facet-keywords_sim']").click
      # click the keyword facet search link
      find("a.facet-anchor.facet_select[href='/concern/monographs/#{monograph.id}?f%5Bkeywords_sim%5D%5B%5D=one&locale=en']").click

      # Facets cause two of these 'x' icons. Clear last search by clicking the one in the sidebar (facet panel)
      find("span.glyphicon.glyphicon-remove", match: :first).click
      expect(page).to_not have_css("span.glyphicon.glyphicon-remove")

      click_button "Sort by First Appearance"
      expect(page).to have_css("button.btn.btn-default.dropdown-toggle[aria-expanded='true']")
      expect(page).to have_css("ul.dropdown-menu", visible: true)
      click_link "Year (Oldest First)"

      # the preceding page load and checks seem to regularly be able to happen faster than the JS can bind...
      # to the next "20 per page" dropdown. So I'm going to reset the page/tab here.
      visit monograph_catalog_path(monograph)

      click_button "20 per page"
      expect(page).to have_css("button.btn.btn-default.dropdown-toggle[aria-expanded='true']")
      expect(page).to have_css("ul.dropdown-menu", visible: true)
      # interestingly, the " per page" bit is in a `<span class="sr-only">`
      click_link "50 per page"
      # alternate link click used for testing
      # find("a[href='#{hyrax_monograph_path(monograph.id, locale: 'en', per_page: 50)}'").click

      find("span.glyphicon.glyphicon-list.view-icon-list").click
    end
  end

  context 'FileSet show page (Monograph parent)' do
    it 'has manual tab navigation that works as expected' do
      visit hyrax_file_set_path(file_set.id)

      # info tab link
      expect(page).to have_css("li.active h2 a#tab-info")
      expect(page).to have_css("a#tab-info[aria-selected=true][aria-expanded=true]")
      expect(page).to_not have_css("a#tab-info[aria-selected=false][aria-expanded=false]")
      expect(page).to_not have_css("a#tab-info[tabindex='-1']")
      # info tab panel
      expect(page).to have_css("section#info[aria-hidden=false]")
      expect(page).to_not have_css("section#info[aria-hidden=true]", visible: false)

      # permissions tab link
      expect(page).to_not have_css("li.active h2 a#tab-permissions")
      expect(page).to_not have_css("a#tab-permissions[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-permissions[aria-selected='false'][aria-expanded='false']")
      expect(page).to have_css("a#tab-permissions[tabindex='-1']")
      # permissions tab panel
      expect(page).to_not have_css("section#permissions[aria-hidden=false]")
      expect(page).to have_css("section#permissions[aria-hidden=true]", visible: false)

      # stats tab link
      # expect(page).to_not have_css("li.active h2 a#tab-stats")
      # expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
      # expect(page).to have_css("a#tab-stats[tabindex='-1']")
      # stats tab panel
      # expect(page).to_not have_css("section#stats[aria-hidden=false]")
      # expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

      # technical-info tab link
      expect(page).to_not have_css("li.active h2 a#tab-technical-info")
      expect(page).to_not have_css("a#tab-technical-info[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-technical-info[aria-selected='false'][aria-expanded='false']")
      expect(page).to have_css("a#tab-technical-info[tabindex='-1']")
      # technical-info tab panel
      expect(page).to_not have_css("section#technical-info[aria-hidden=false]")
      expect(page).to have_css("section#technical-info[aria-hidden=true]", visible: false)

      # click permissions tab
      find("#tab-permissions").click

      # permissions tab link
      expect(page).to have_css("li.active h2 a#tab-permissions")
      expect(page).to have_css("a#tab-permissions[aria-selected=true][aria-expanded=true]")
      expect(page).to_not have_css("a#tab-permissions[aria-selected='false'][aria-expanded='false']")
      expect(page).to_not have_css("a#tab-permissions[tabindex='-1']")
      # permissions tab panel
      expect(page).to have_css("section#permissions[aria-hidden=false]")
      expect(page).to_not have_css("section#permissions[aria-hidden=true]", visible: false)

      # info tab link
      expect(page).to_not have_css("li.active h2 a#tab-info")
      expect(page).to_not have_css("a#tab-info[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-info[aria-selected=false][aria-expanded=false]")
      expect(page).to have_css("a#tab-info[tabindex='-1']")
      # info tab panel
      expect(page).to_not have_css("section#info[aria-hidden=false]")
      expect(page).to have_css("section#info[aria-hidden=true]", visible: false)

      # stats tab link
      # expect(page).to_not have_css("li.active h2 a#tab-stats")
      # expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
      # expect(page).to have_css("a#tab-stats[tabindex='-1']")
      # stats tab panel
      # expect(page).to_not have_css("section#stats[aria-hidden=false]")
      # expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

      # technical-info tab link
      expect(page).to_not have_css("li.active h2 a#tab-technical-info")
      expect(page).to_not have_css("a#tab-technical-info[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-technical-info[aria-selected='false'][aria-expanded='false']")
      expect(page).to have_css("a#tab-technical-info[tabindex='-1']")
      # technical-info tab panel
      expect(page).to_not have_css("section#technical-info[aria-hidden=false]")
      expect(page).to have_css("section#technical-info[aria-hidden=true]", visible: false)

      # click stats tab
      # find("#tab-stats").click

      # stats tab link
      # expect(page).to have_css("li.active h2 a#tab-stats")
      # expect(page).to have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
      # expect(page).to_not have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
      # expect(page).to_not have_css("a#tab-stats[tabindex='-1']")
      # stats tab panel
      # expect(page).to have_css("section#stats[aria-hidden=false]")
      # expect(page).to_not have_css("section#stats[aria-hidden=true]", visible: false)

      # info tab link
      # expect(page).to_not have_css("li.active h2 a#tab-info")
      # expect(page).to_not have_css("a#tab-info[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-info[aria-selected=false][aria-expanded=false]")
      # expect(page).to have_css("a#tab-info[tabindex='-1']")
      # info tab panel
      # expect(page).to_not have_css("section#info[aria-hidden=false]")
      # expect(page).to have_css("section#info[aria-hidden=true]", visible: false)

      # permissions tab link
      # expect(page).to_not have_css("li.active h2 a#tab-permissions")
      # expect(page).to_not have_css("a#tab-permissions[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-permissions[aria-selected='false'][aria-expanded='false']")
      # expect(page).to have_css("a#tab-permissions[tabindex='-1']")
      # permissions tab panel
      # expect(page).to_not have_css("section#permissions[aria-hidden=false]")
      # expect(page).to have_css("section#permissions[aria-hidden=true]", visible: false)

      # technical-info tab link
      # expect(page).to_not have_css("li.active h2 a#tab-technical-info")
      # expect(page).to_not have_css("a#tab-technical-info[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-technical-info[aria-selected='false'][aria-expanded='false']")
      # expect(page).to have_css("a#tab-technical-info[tabindex='-1']")
      # technical-info tab panel
      # expect(page).to_not have_css("section#technical-info[aria-hidden=false]")
      # expect(page).to have_css("section#technical-info[aria-hidden=true]", visible: false)

      # click technical info tab
      find("#tab-technical-info").click

      # technical-info tab link
      expect(page).to have_css("li.active h2 a#tab-technical-info")
      expect(page).to have_css("a#tab-technical-info[aria-selected=true][aria-expanded=true]")
      expect(page).to_not have_css("a#tab-technical-info[aria-selected='false'][aria-expanded='false']")
      expect(page).to_not have_css("a#tab-technical-info[tabindex='-1']")
      # technical-info tab panel
      expect(page).to have_css("section#technical-info[aria-hidden=false]")
      expect(page).to_not have_css("section#technical-info[aria-hidden=true]", visible: false)

      # info tab link
      expect(page).to_not have_css("li.active h2 a#tab-info")
      expect(page).to_not have_css("a#tab-info[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-info[aria-selected=false][aria-expanded=false]")
      expect(page).to have_css("a#tab-info[tabindex='-1']")
      # info tab panel
      expect(page).to_not have_css("section#info[aria-hidden=false]")
      expect(page).to have_css("section#info[aria-hidden=true]", visible: false)

      # permissions tab link
      expect(page).to_not have_css("li.active h2 a#tab-permissions")
      expect(page).to_not have_css("a#tab-permissions[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-permissions[aria-selected='false'][aria-expanded='false']")
      expect(page).to have_css("a#tab-permissions[tabindex='-1']")
      # permissions tab panel
      expect(page).to_not have_css("section#permissions[aria-hidden=false]")
      expect(page).to have_css("section#permissions[aria-hidden=true]", visible: false)

      # stats tab link
      # expect(page).to_not have_css("li.active h2 a#tab-stats")
      # expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
      # expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
      # expect(page).to have_css("a#tab-stats[tabindex='-1']")
      # stats tab panel
      # expect(page).to_not have_css("section#stats[aria-hidden=false]")
      # expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)
    end
  end
end
