# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Press statistics page Bootstrap tabs", type: :system, browser: true do
  let(:press) { create(:press, readership_map_url: 'http://www.example.com/default.htm', google_analytics_url: 'http://www.example.com/default.htm') }

  # Comment this method out to see screenshots on failures in tmp/screenshots
  def take_failed_screenshot
    false
  end

  context 'Press statistics page' do
    it 'has manual tab navigation that works as expected' do
      visit press_statistics_path(press.subdomain)

      # map tab link
      expect(page).to have_css("li.active h2 a#tab-map-press-stats")
      expect(page).to have_css("a#tab-map-press-stats[aria-selected=true][aria-expanded=true]")
      expect(page).to_not have_css("a#tab-map-press-statsc[aria-selected=false][aria-expanded=false]")
      expect(page).to_not have_css("a#tab-map-press-stats[tabindex='-1']")
      # map tab panel
      expect(page).to have_css("section#map[aria-hidden=false]")
      expect(page).to_not have_css("section#map[aria-hidden=true]", visible: false)

      # analytics tab link
      expect(page).to_not have_css("li.active h2 a#tab-analytics-press-stats")
      expect(page).to_not have_css("a#tab-analytics-press-stats[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-analytics-press-stats[aria-selected='false'][aria-expanded='false']")
      expect(page).to have_css("a#tab-analytics-press-stats[tabindex='-1']")
      # analytics tab panel
      expect(page).to_not have_css("section#analytics[aria-hidden=false]")
      expect(page).to have_css("section#analytics[aria-hidden=true]", visible: false)

      # click analytics tab
      find("#tab-analytics-press-stats").click
      # analytics tab link
      expect(page).to have_css("li.active h2 a#tab-analytics-press-stats")
      expect(page).to have_css("a#tab-analytics-press-stats[aria-selected=true][aria-expanded=true]")
      expect(page).to_not have_css("a#tab-analytics-press-stats[aria-selected='false'][aria-expanded='false']")
      expect(page).to_not have_css("a#tab-analytics-press-stats[tabindex='-1']")
      # analytics tab panel
      expect(page).to have_css("section#analytics[aria-hidden=false]")
      expect(page).to_not have_css("section#analytics[aria-hidden=true]", visible: false)

      # map tab link
      expect(page).to_not have_css("li.active h2 a#tab-map-press-stats")
      expect(page).to_not have_css("a#tab-map-press-stats[aria-selected=true][aria-expanded=true]")
      expect(page).to have_css("a#tab-map-press-stats[aria-selected=false][aria-expanded=false]")
      expect(page).to have_css("a#tab-map-press-stats[tabindex='-1']")
      # map tab panel
      expect(page).to_not have_css("section#map[aria-hidden=false]")
      expect(page).to have_css("section#map[aria-hidden=true]", visible: false)
    end
  end
end
