require 'rails_helper'

feature 'Create a section' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }
    let!(:monograph) { create(:monograph, user: user) }
    let!(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
    end

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
