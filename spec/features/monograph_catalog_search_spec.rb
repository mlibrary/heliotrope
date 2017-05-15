# frozen_string_literal: true

require 'rails_helper'

feature 'Monograph Catalog Search' do
  let(:user) { create(:platform_admin) }
  let(:monograph) { create(:monograph, user: user, title: ["Weird Bogs"], buy_url: ['https://example.com']) }
  let(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

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

    click_link 'Manage Monograph and Files'
    click_link 'Attach a File'
    fill_in 'Title', with: 'Strange Marshes'
    fill_in 'Caption', with: 'onion'
    fill_in 'Alternative Text', with: 'garlic'
    fill_in 'Abstract or Summary', with: 'tomato'
    fill_in 'Contributor', with: 'potato'
    fill_in 'Keywords', with: 'squash'
    fill_in 'Transcript', with: 'broccoli'
    fill_in 'Translation(s)', with: 'cauliflower'
    attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
    click_button 'Attach to Monograph'

    click_link 'Manage Monograph and Files'
    click_link 'Attach a File'
    fill_in 'Title', with: 'Unruly Puddles'
    fill_in 'Caption', with: 'monkey'
    fill_in 'Alternative Text', with: 'lizard'
    fill_in 'Abstract or Summary', with: 'elephant'
    fill_in 'Contributor', with: 'rhino'
    fill_in 'Keywords', with: 'snake'
    fill_in 'Transcript', with: 'tiger'
    fill_in 'Translation(s)', with: 'mouse'
    attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
    click_button 'Attach to Monograph'

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
