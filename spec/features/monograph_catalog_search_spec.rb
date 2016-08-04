require 'rails_helper'

feature 'Monograph Catalog Search' do
  let(:user) { create(:platform_admin) }
  let(:monograph) { create(:monograph, user: user, title: ["Weird Bogs"]) }

  before do
    login_as user
    stub_out_redis
  end

  it 'has the correct search field form' do
    visit monograph_catalog_path(monograph.id)
    expect(page).to have_selector("form[action='/concern/monographs/#{monograph.id}']")
  end

  scenario 'searches the monograph catalog page' do
    visit monograph_catalog_path(monograph.id)

    click_link 'Manage Monograph and Files'
    click_link 'Attach a File'
    fill_in 'Title', with: 'Strange Marshes'
    attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
    click_button 'Attach to Monograph'

    click_link 'Manage Monograph and Files'
    click_link 'Attach a File'
    fill_in 'Title', with: 'Unruly Puddles'
    attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
    click_button 'Attach to Monograph'

    fill_in 'catalog_search', with: 'Unruly'
    click_button 'keyword-search-submit'

    expect(page).to have_content 'Unruly Puddles'
    expect(page).to_not have_content 'Strange Marshes'
  end
end
