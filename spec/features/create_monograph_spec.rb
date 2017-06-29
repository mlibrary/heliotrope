# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Monograph`
require 'rails_helper'
include Warden::Test::Helpers

# Use js: true to switch to the Capybara.javascript_driver (:selenium by default), or provide a :driver option to switch to one specific driver. For example:
# describe 'some stuff which requires js', js: true do
#   it 'will use the default js driver'
#   it 'will switch to one specific driver', :driver => :webkit
# end

# NOTE: If you generated more than one work, you have to set "js: true"
RSpec.feature 'Create a Monograph', js: true do
  context 'as platform administrator' do
    let(:user) { create(:platform_admin) }

    before do
      AdminSet.find_or_create_default_admin_set_id
      login_as user
    end

    scenario do
      visit '/dashboard?locale=en'
      expect(page).to have_content 'Works'
      expect(page).to have_link 'Works'
      click_link 'Works'
      sleep 2
      expect(page).to have_content 'Add new work'
      expect(page).to have_link 'Add new work'
      click_link 'Add new work'
      sleep 2
      # If you generate more than one work uncomment these lines
      expect(page).to have_content 'Monograph'
      choose 'payload_concern', option: 'Monograph'
      click_button 'Create work'
      sleep 2
      expect(page).to have_content 'Add New Monograph'
    end
  end
end
