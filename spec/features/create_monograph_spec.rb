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
  context 'a logged in hyrax user' do
    let(:user_attributes) do
      { email: 'test@example.com' }
    end
    let(:user) do
      User.new(user_attributes) { |u| u.save(validate: false) }
    end

    before do
      AdminSet.find_or_create_default_admin_set_id
      login_as user
    end

    scenario do
      visit '/dashboard'
      click_link "Works"
      click_link "Add new work"

      # If you generate more than one work uncomment these lines
      choose "payload_concern", option: "Monograph"
      click_button "Create work"

      expect(page).to have_content "Add New Monograph"
    end
  end

  # context 'a logged in heliotrope user' do
  #   let(:user) { create(:platform_admin) }
  #   let!(:press) { create(:press) }
  #
  #   before do
  #     login_as user
  #     stub_out_redis
  #   end
  #
  #   scenario do
  #     visit new_hyrax_monograph_path
  #     fill_in 'monograph[title][]', with: 'Test monograph'
  #     # fill_in 'Title', with: 'Test monograph'
  #     fill_in 'Author (last name)', with: 'Johns'
  #     fill_in 'Author (first name)', with: 'Jimmy'
  #     fill_in 'Additional Authors', with: 'Sub Way'
  #     select press.name, from: 'Publisher'
  #     fill_in 'ISBN (Hardcover)', with: '123-456-7890'
  #     click_button 'Save'
  #
  #     expect(page).to have_content 'Test monograph'
  #     expect(page).to have_content '123-456-7890'
  #     # Monograph page has authors
  #     expect(page).to have_content 'Jimmy Johns and Sub Way'
  #   end
  # end
end
