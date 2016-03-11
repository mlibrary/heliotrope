require 'rails_helper'

feature 'Create a collection' do
  context 'a logged in user' do
    before do
      login_as create(:user)
    end

    scenario do
      visit Hydra::Collections::Engine.routes.url_helpers.new_collection_path
      fill_in 'Title', with: 'Test collection'
      click_button 'Create Collection'
      expect(page).to have_content 'Collection was successfully created.'
    end
  end
end
