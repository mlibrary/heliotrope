# frozen_string_literal: true

require 'rails_helper'

feature 'Create a collection' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }
    before do
      login_as user
    end

    scenario do
      visit new_collection_path
      fill_in 'Title', with: 'Test collection'
      click_button 'Create Collection'
      expect(page).to have_content 'Collection was successfully created.'
    end
  end
end
