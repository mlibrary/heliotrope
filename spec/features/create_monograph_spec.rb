require 'rails_helper'

feature 'Create a monograph' do
  context 'a logged in user' do
    before do
      login_as create(:user)
    end

    scenario do
      visit new_curation_concerns_monograph_path
      fill_in 'Title', with: 'Test monograph'
      click_button 'Create Monograph'
      expect(page).to have_content 'Test monograph'
    end
  end
end
