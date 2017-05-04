# frozen_string_literal: true

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
      fill_in 'Author (last name)', with: 'Johns'
      fill_in 'Author (first name)', with: 'Jimmy'
      fill_in 'Additional Authors', with: 'Sub Way'
      select press.name, from: 'Publisher'
      fill_in 'ISBN (Hardcover)', with: '123-456-7890'
      click_button 'Create Monograph'
      expect(page).to have_content 'Test monograph'
      expect(page).to have_content '123-456-7890'
      # Monograph page has authors
      expect(page).to have_content 'Jimmy Johns and Sub Way'
    end
  end
end
