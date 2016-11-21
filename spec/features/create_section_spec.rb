require 'rails_helper'

feature 'Create a section' do
  context 'a logged in user' do
    before do
      Section.destroy_all
      Monograph.destroy_all
    end
    let(:user) { create(:platform_admin) }
    let!(:monograph) { create(:monograph, user: user) }
    before do
      login_as user
    end

    scenario do
      visit new_curation_concerns_section_path
      fill_in 'Title', with: 'Test section'
      select monograph.title.first, from: "Monograph"
      click_button 'Create Section'
      expect(page).to have_content 'Test section'

      visit monograph_show_path(monograph)
      within '.sections' do
        expect(page).to have_link 'Test section'
      end
    end
  end
end
