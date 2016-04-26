require 'rails_helper'

feature 'Create a monograph' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }
    let!(:press) { create(:press) }

    before do
      login_as user
    end

    scenario do
      visit new_curation_concerns_monograph_path
      fill_in 'Title', with: 'Test monograph'
      select press.name, from: 'Press'
      fill_in 'Date Published', with: 'Oct 20th'
      click_button 'Create Monograph'
      expect(page).to have_content 'Test monograph'
      expect(page).to have_content 'Oct 20th'
    end
  end
end
