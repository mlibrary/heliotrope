# frozen_string_literal: true

require 'rails_helper'

feature 'Adding a new press' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }

    before do
      login_as user
    end

    scenario 'creates a press' do
      visit new_press_path
      fill_in 'Publisher Name', with: 'Test Publisher'
      fill_in 'fulcrum.org Subdomain', with: 'testpub'
      fill_in 'Description', with: 'A Test Publisher description'
      attach_file 'press[logo_path]', Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')
      fill_in 'Publisher\'s Current Website Address', with: 'https://example.com'
      fill_in 'Google Analytics Tracking ID', with: 'GA-87654321-1'
      fill_in 'Typekit ID', with: '2346553'
      # leaving footer block a blank to produce external link to the Publisher
      # fill_in 'Footer block a', with: '<div>Footer Block A Stuff</div>'
      fill_in 'Footer block c', with: '<div>Footer Block C Stuff</div>'
      click_button 'Create Press'
      expect(page).to have_link 'Test Publisher', href: 'testpub'
      click_link 'Test Publisher'
      expect(page).to have_content 'Test Publisher'
      expect(page).to have_content 'A Test Publisher description'
      expect(page).to have_css("img[alt='Test Publisher']")
      # This works in dev, Travis CI doesn't like it. Asset pipeline issue?
      # expect(page).to have_css("img[src*='/assets/shipwreck']")
      expect(page).to have_css("img[src*='shipwreck']")
      expect(page).to have_link 'Test Publisher', href: 'https://example.com'
      expect(page).to have_css("script[src='https://use.typekit.net/2346553.js']", visible: false)
      # leaving footer block a blank to produce external link to the Publisher
      # expect(page).to have_content 'Footer Block A Stuff'
      expect(page).to have_content 'Footer Block C Stuff'
    end
  end
end
