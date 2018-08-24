# frozen_string_literal: true

require 'rails_helper'

describe 'Create a collection' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }

    before do
      cosign_login_as user
    end

    it do
      visit hyrax.new_dashboard_collection_path
      fill_in 'Title', with: 'Test collection'
      click_button 'Create Collection'
      expect(page).to have_content 'Collection was successfully created.'
    end
  end
end
