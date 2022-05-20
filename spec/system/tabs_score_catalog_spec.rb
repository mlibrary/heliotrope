# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Score Bootstrap tabs", type: :system, browser: true do
  skip "We don't have Scores and never will so it's not worth maintaning these buggy system specs, see cleanup ticket HELIO-3583" do
    let(:press) { create(:press, subdomain: Services.score_press) }
    let(:score) { create(:score, press: press.subdomain, user: User.batch_user, visibility: "open", representative_id: cover.id) }
    let(:cover) { create(:file_set, visibility: "open", content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
    let(:file_set) { create(:file_set, visibility: "open", content: File.open(File.join(fixture_path, 'csv', 'shipwreck.jpg'))) }
    let(:epub) { create(:file_set, visibility: "open", allow_download: 'no', content: File.open(File.join(fixture_path, 'moby-dick.epub'))) }
    let(:fr) { create(:featured_representative, work_id: score.id, file_set_id: epub.id, kind: 'epub') }

    before do
      stub_out_redis
      score.ordered_members = [cover, epub, file_set]
      score.save!
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

    context 'Score catalog page with EPUB and resource FileSet' do
      it 'has manual tab navigation works as expected' do
        visit score_catalog_path(score)

        # toc tab link
        expect(page).to have_css("li.active h2 a#tab-toc")
        expect(page).to have_css("a#tab-toc[aria-selected=true][aria-expanded=true]")
        expect(page).to_not have_css("a#tab-toc[aria-selected=false][aria-expanded=false]")
        expect(page).to_not have_css("a#tab-toc[tabindex='-1']")
        # toc tab panel
        expect(page).to have_css("section#toc[aria-hidden=false]")
        expect(page).to_not have_css("section#toc[aria-hidden=true]", visible: false)

        # resources tab link
        expect(page).to_not have_css("li.active h2 a#tab-resources")
        expect(page).to_not have_css("a#tab-resources[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-resources[aria-selected='false'][aria-expanded='false']")
        expect(page).to have_css("a#tab-resources[tabindex='-1']")
        # resources tab panel
        expect(page).to_not have_css("section#resources[aria-hidden=false]")
        expect(page).to have_css("section#resources[aria-hidden=true]", visible: false)

        # stats tab link
        expect(page).to_not have_css("li.active h2 a#tab-stats")
        expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to_not have_css("section#stats[aria-hidden=false]")
        expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

        # click resources tab
        find("#tab-resources").click
        # resources tab link
        expect(page).to have_css("li.active h2 a#tab-resources")
        expect(page).to have_css("a#tab-resources[aria-selected=true][aria-expanded=true]")
        expect(page).to_not have_css("a#tab-resources[aria-selected='false'][aria-expanded='false']")
        expect(page).to_not have_css("a#tab-resources[tabindex='-1']")
        # resources tab panel
        expect(page).to have_css("section#resources[aria-hidden=false]")
        expect(page).to_not have_css("section#resources[aria-hidden=true]", visible: false)

        # toc tab link
        expect(page).to_not have_css("li.active h2 a#tab-toc")
        expect(page).to_not have_css("a#tab-toc[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-toc[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-toc[tabindex='-1']")
        # toc tab panel
        expect(page).to_not have_css("section#toc[aria-hidden=false]")
        expect(page).to have_css("section#toc[aria-hidden=true]", visible: false)

        # stats tab link
        expect(page).to_not have_css("li.active h2 a#tab-stats")
        expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to_not have_css("section#stats[aria-hidden=false]")
        expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

        # click stats tab
        find("#tab-stats").click
        # stats tab link
        expect(page).to have_css("li.active h2 a#tab-stats")
        expect(page).to have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to_not have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to_not have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to have_css("section#stats[aria-hidden=false]")
        expect(page).to_not have_css("section#stats[aria-hidden=true]", visible: false)

        # toc tab link
        expect(page).to_not have_css("li.active h2 a#tab-toc")
        expect(page).to_not have_css("a#tab-toc[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-toc[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-toc[tabindex='-1']")
        # toc tab panel
        expect(page).to_not have_css("section#toc[aria-hidden=false]")
        expect(page).to have_css("section#toc[aria-hidden=true]", visible: false)

        # resources tab link
        expect(page).to_not have_css("li.active h2 a#tab-resources")
        expect(page).to_not have_css("a#tab-resources[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-resources[aria-selected='false'][aria-expanded='false']")
        expect(page).to have_css("a#tab-resources[tabindex='-1']")
        # resources tab panel
        expect(page).to_not have_css("section#resources[aria-hidden=false]")
        expect(page).to have_css("section#resources[aria-hidden=true]", visible: false)
      end

      it 'has Blacklight resources searching that opens the resources tab' do
        visit score_catalog_path(score)
        # NB: if we add a resources search box to the Score catalog then that should be tested here. Same with...
        # gallery/list buttons and sort options. Those are on the Monograph catalog but not here as of Jan 2020.

        # click resources tab to test facet search
        find("#tab-resources").click
        expect(page).to have_css("li.active h2 a#tab-resources")

        # open the facet panel (this 'Type' facet will probably be removed when Score goes live)
        find("div[data-target='#facet-human_readable_type_sim']").click
        # click the 'Type' facet search link
        find("a.facet-anchor.facet_select[href='/concern/scores/#{score.id}?f%5Bhuman_readable_type_sim%5D%5B%5D=File&locale=en']").click
        # verify resources tab is visible as above (we'll skip checking the other tabs)
        # resources tab link
        expect(page).to have_css("li.active h2 a#tab-resources")
        expect(page).to have_css("a#tab-resources[aria-selected=true][aria-expanded=true]")
        expect(page).to_not have_css("a#tab-resources[aria-selected='false'][aria-expanded='false']")
        expect(page).to_not have_css("a#tab-resources[tabindex='-1']")
        # resources tab panel
        expect(page).to have_css("section#resources[aria-hidden=false]")
        expect(page).to_not have_css("section#resources[aria-hidden=true]", visible: false)

        # clear last search
        # Facets cause two of these 'x' icons. Clear last search by clicking the one in the sidebar (facet panel)
        find("span.glyphicon.glyphicon-remove", match: :first).click
        expect(page).to_not have_css("span.glyphicon.glyphicon-remove")

        # click resources tab to test results pagination options
        find("#tab-resources").click
        expect(page).to have_css("li.active h2 a#tab-resources")

        click_button "10 per page"
        expect(page).to have_css("button.btn.btn-default.dropdown-toggle[aria-expanded='true']")
        expect(page).to have_css("ul.dropdown-menu", visible: true)
        # interestingly, the " per page" bit is in a `<span class="sr-only">`
        click_link "50 per page"

        # verify resources tab is visible
        # resources tab link
        expect(page).to have_css("li.active h2 a#tab-resources")
        expect(page).to have_css("a#tab-resources[aria-selected=true][aria-expanded=true]")
        expect(page).to_not have_css("a#tab-resources[aria-selected='false'][aria-expanded='false']")
        expect(page).to_not have_css("a#tab-resources[tabindex='-1']")
        # resources tab panel
        expect(page).to have_css("section#resources[aria-hidden=false]")
        expect(page).to_not have_css("section#resources[aria-hidden=true]", visible: false)
      end
    end

    context 'FileSet show page (Score parent)' do
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
        expect(page).to_not have_css("li.active h2 a#tab-stats")
        expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to_not have_css("section#stats[aria-hidden=false]")
        expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

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
        expect(page).to_not have_css("li.active h2 a#tab-stats")
        expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to_not have_css("section#stats[aria-hidden=false]")
        expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)

        # technical-info tab link
        expect(page).to_not have_css("li.active h2 a#tab-technical-info")
        expect(page).to_not have_css("a#tab-technical-info[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-technical-info[aria-selected='false'][aria-expanded='false']")
        expect(page).to have_css("a#tab-technical-info[tabindex='-1']")
        # technical-info tab panel
        expect(page).to_not have_css("section#technical-info[aria-hidden=false]")
        expect(page).to have_css("section#technical-info[aria-hidden=true]", visible: false)

        # click stats tab
        find("#tab-stats").click
        # stats tab link
        expect(page).to have_css("li.active h2 a#tab-stats")
        expect(page).to have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to_not have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to_not have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to have_css("section#stats[aria-hidden=false]")
        expect(page).to_not have_css("section#stats[aria-hidden=true]", visible: false)

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

        # technical-info tab link
        expect(page).to_not have_css("li.active h2 a#tab-technical-info")
        expect(page).to_not have_css("a#tab-technical-info[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-technical-info[aria-selected='false'][aria-expanded='false']")
        expect(page).to have_css("a#tab-technical-info[tabindex='-1']")
        # technical-info tab panel
        expect(page).to_not have_css("section#technical-info[aria-hidden=false]")
        expect(page).to have_css("section#technical-info[aria-hidden=true]", visible: false)

        # click stats tab
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
        expect(page).to_not have_css("li.active h2 a#tab-stats")
        expect(page).to_not have_css("a#tab-stats[aria-selected=true][aria-expanded=true]")
        expect(page).to have_css("a#tab-stats[aria-selected=false][aria-expanded=false]")
        expect(page).to have_css("a#tab-stats[tabindex='-1']")
        # stats tab panel
        expect(page).to_not have_css("section#stats[aria-hidden=false]")
        expect(page).to have_css("section#stats[aria-hidden=true]", visible: false)
      end
    end
  end
end
