# frozen_string_literal: true

require 'rails_helper'

feature 'FileSet Search' do
  let(:user) { create(:platform_admin) }
  let(:monograph) { create(:monograph, user: user, title: ["Yellow"], representative_id: cover.id) }
  let(:cover) { create(:file_set) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  before do
    monograph.ordered_members << cover
    monograph.save!
    login_as user
    stub_out_redis
  end

  scenario 'searches the monograph catalog page, not the catalog page' do
    visit monograph_catalog_path(monograph.id)

    click_link 'Manage Monograph and Files'
    click_link 'Attach a File'
    fill_in 'Title', with: 'Blue'
    fill_in 'Caption', with: "Damage report! Mr. Worf, you do remember how to fire phasers? Worf, It's better than music. It's jazz."
    attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
    click_button 'Attach to Monograph'

    click_link 'Manage Monograph and Files'
    click_link 'miranda.jpg'

    expect(page).to have_selector("form[action='/concern/monographs/#{monograph.id}?locale=en']")

    fill_in 'catalog_search', with: 'jazz'
    click_button 'keyword-search-submit'

    expect(page).to have_content 'Mr. Worf'

    # Selectors needed for assets/javascripts/ga_event_tracking.js
    # If these change, fix here then update ga_event_tracking.js
    expect(page).to have_selector('#keyword-search-submit')
    expect(page).to have_selector('#catalog_search')
  end
end
