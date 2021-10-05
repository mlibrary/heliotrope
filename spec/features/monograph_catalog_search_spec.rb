# frozen_string_literal: true

require 'rails_helper'

describe 'Monograph Catalog Search' do
  let(:user) { create(:platform_admin) }
  let(:monograph) do
    m = build(:monograph, user: user,
                          title: ["Weird Bogs"],
                          buy_url: ['https://example.com'],
                          representative_id: cover.id)
    m.ordered_members = [cover, fs1, fs2]
    m.save!
    m
  end
  let(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  let(:cover) { create(:public_file_set, user: user) }
  let(:fs1) {
    create(:file_set, title: ['Strange Marshes'],
                      caption: ['onion'],
                      alt_text: ['garlic'],
                      description: ['tomato'],
                      contributor: ['potato'],
                      keywords: ['squash'],
                      transcript: 'broccoli',
                      translation: ['cauliflower'])
  }

  let(:fs2) {
    create(:file_set, title: ['Unruly Puddles'],
                      caption: ['monkey'],
                      alt_text: ['lizard'],
                      description: ['elephant'],
                      contributor: ['rhino'],
                      keywords: ['snake'],
                      transcript: 'tiger',
                      translation: ['mouse'])
  }

  before do
    login_as user
    stub_out_redis
  end

  it 'has the correct search field form' do
    visit monograph_catalog_path(monograph.id)
    expect(page).to have_selector("form[action='/concern/monographs/#{monograph.id}?locale=en']")
  end

  it 'searches the monograph catalog page' do
    visit monograph_catalog_path(monograph.id)

    expect(page).to_not have_content("Your search has returned")

    # Selectors needed for assets/javascripts/ga_event_tracking.js
    # If these change, fix here then update ga_event_tracking.js
    expect(page).to have_selector('#documents .document h4.index_title a')
    expect(page).to have_selector('#monograph-buy-btn')
    expect(page).to have_selector('#resources-search-submit')
    expect(page).to have_selector('#resources_search')

    fill_in 'resources_search', with: 'Unruly'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'monkey'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'lizard'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'elephant'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'rhino'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'snake'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'tiger'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    fill_in 'resources_search', with: 'mouse'
    click_button 'resources-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).not_to have_content 'Strange Marshes'
    expect(page).to have_content("Your search has returned 1 resource attached to Weird Bogs")

    # Monograph catalog defaults to list view
    expect(page).to have_css(".view-type-group.btn-group[role=tablist]")
    expect(page).to have_css("a.btn.btn-default.view-type-list.active[href*='view=list'][role=tab][aria-selected=true]")
    expect(page).to have_css("a.btn.btn-default.view-type-gallery[href*='view=gallery'][role=tab][aria-selected=false]")

    # also check gallery view
    visit monograph_catalog_path id: monograph.id, view: 'gallery', oa_marker: 'monograph'

    expect(page).to have_css(".view-type-group.btn-group[role=tablist]")
    expect(page).to have_css("a.btn.btn-default.view-type-list[href*='view=list'][role=tab][aria-selected=false]")
    expect(page).to have_css("a.btn.btn-default.view-type-gallery.active[href*='view=gallery'][role=tab][aria-selected=true]")

    expect(page).to have_selector("#documents.row.gallery")
    expect(page).to have_selector(".gallery .document .thumbnail .caption")
    expect(page).to have_content("Unruly Puddles")
    expect(page).to_not have_content("Your search has returned")
  end
end
