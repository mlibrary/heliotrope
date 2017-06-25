# frozen_string_literal: true

require 'rails_helper'

feature 'Monograph Catalog Search' do
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
  let(:fs1) { create(:file_set, title: ['Strange Marshes'],
                                caption: ['onion'],
                                alt_text: ['garlic'],
                                description: ['tomato'],
                                contributor: ['potato'],
                                keywords: ['squash'],
                                transcript: 'broccoli',
                                translation: ['cauliflower']) }

  let(:fs2) { create(:file_set, title: ['Unruly Puddles'],
                                caption: ['monkey'],
                                alt_text: ['lizard'],
                                description: ['elephant'],
                                contributor: ['rhino'],
                                keywords: ['snake'],
                                transcript: 'tiger',
                                translation: ['mouse']) }

  before do
    login_as user
    stub_out_redis
  end

  it 'has the correct search field form' do
    visit monograph_catalog_path(monograph.id)
    expect(page).to have_selector("form[action='/concern/monographs/#{monograph.id}?locale=en']")
  end

  scenario 'searches the monograph catalog page' do
    visit monograph_catalog_path(monograph.id)
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to have_content 'Strange Marshes'

    # Selectors needed for assets/javascripts/ga_event_tracking.js
    # If these change, fix here then update ga_event_tracking.js
    expect(page).to have_selector('#documents .document h4.index_title a')
    expect(page).to have_selector('#monograph-buy-btn')
    expect(page).to have_selector('#keyword-search-submit')
    expect(page).to have_selector('#catalog_search')

    fill_in 'catalog_search', with: 'Unruly'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'monkey'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'lizard'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'elephant'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'rhino'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'snake'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'tiger'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    fill_in 'catalog_search', with: 'mouse'
    click_button 'keyword-search-submit'
    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'

    # Gallery view
    visit monograph_catalog_path id: monograph.id, view: 'gallery'
    expect(page).to have_selector("#documents.row.gallery")
    expect(page).to have_selector(".gallery .document .thumbnail .caption")
    expect(page).to have_content("Unruly Puddles")
  end
end
