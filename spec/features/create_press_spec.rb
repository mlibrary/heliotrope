# frozen_string_literal: true

require 'rails_helper'

describe 'Adding a new press' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }

    before do
      login_as user
    end

    it 'creates a press' do
      visit new_press_path
      fill_in 'Publisher Name', with: 'Test Publisher'
      fill_in 'fulcrum.org Subdomain', with: 'testpub'
      fill_in 'Description', with: 'A Test Publisher description'
      attach_file 'press[logo_path]', Rails.root.join('spec', 'fixtures', 'csv', 'import', 'shipwreck.jpg')
      fill_in 'Publisher\'s Current Website Address', with: 'https://example.com'
      fill_in 'Google Analytics Tracking ID', with: 'GA-87654321-1'
      fill_in 'Google Analytics Data Studio URL', with: 'https://www.example.com/GA/ReadReadRead'
      fill_in 'Typekit ID', with: '2346553'
      # leaving footer block a blank to produce external link to the Publisher
      # fill_in 'Footer block a', with: '<div>Footer Block A Stuff</div>'
      fill_in 'Footer block c', with: '<div>Footer Block C Stuff</div>'
      click_button 'Save'
      expect(page).to have_link 'Test Publisher', href: '/testpub?locale=en'
      click_link 'Test Publisher'
      expect(page).to have_content 'Test Publisher'
      expect(page).to have_content 'A Test Publisher description'
      expect(page).to have_css("img[alt='Test Publisher']")

      expect(page).to have_css("img[src*='shipwreck']")
      # Default Fulcrum logo only used once, in the right-side footer, i.e. not used for the press
      expect(page).to have_css("img[src*='fulcrum-white-50px']", count: 1)

      expect(page).to have_link 'Test Publisher', href: 'https://example.com'
      expect(page).to have_css("link[href='https://use.typekit.net/2346553.css']", visible: false)
      # leaving footer block a blank to produce external link to the Publisher
      # expect(page).to have_content 'Footer Block A Stuff'
      expect(page).to have_content 'Footer Block C Stuff'

      # go back in and remove the logo and footer_block_c to test default behaviors
      visit edit_press_path 'testpub'
      find(:css, '#press_remove_logo_path').set(true)
      fill_in 'Footer block c', with: ''
      click_button 'Save'
      click_link 'Test Publisher'

      # Check that the default logo is being used, note that this logo is always used *once* in the...
      # right-side footer. The press logo is shown twice, so this logo appears 3 times for a logo-less press
      expect(page).to have_css("img[src*='fulcrum-white-50px']", count: 3)
      expect(page).not_to have_css("img[src*='shipwreck']")

      # no footer_block_c results in default copyright message
      expect(page).not_to have_content 'Footer Block C Stuff'
      expect(page).to have_css('.row.press-block-c .col-sm-12 p', text: "© Test Publisher #{Time.current.year}")
    end
  end
end
