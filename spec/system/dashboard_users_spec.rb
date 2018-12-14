# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Dashboard User Types', type: :system do
  context "an anonymous user" do
    it "has no user dropdown menu and no dashboards" do
      visit presses_path
      expect(page.has_css?('li.my-actions')).to be false

      visit main_app.fulcrum_path
      # If you're not a platform_admin, the /fulcrum route doesn't even exist for you
      # and you get pushed to the default press route
      expect(page).to have_content "The press \"fulcrum\" doesn't exist!"

      visit hyrax.dashboard_path
      # in production this goes to shibboleth login but in dev/test it goes to fake HTTP authentication login page
      expect(page).to have_content("You need to sign in or sign up before continuing.")
      expect(page).to have_content("Fake HTTP Authentication")
    end
  end

  context "an anonymous institutional user" do
    let(:institution) { create(:institution) }

    before { setup_current_institution(institution) }

    after { teardown_current_institution }

    it "has the institution but does not get a dashboard" do
      visit presses_path
      expect(page.has_css?('li.my-actions')).to be true
      expect(find('.user-display-name').text).to eq institution.name

      visit hyrax.dashboard_path
      expect(page).to have_content("You need to sign in or sign up before continuing.")
      expect(page).to have_content("Fake HTTP Authentication")

      visit main_app.fulcrum_path
      expect(page).to have_content "The press \"fulcrum\" doesn't exist!"
    end
  end

  context 'a guest user a.k.a. user not in the users table' do
    let(:guest) { User.guest(user_key: "nobody@nothing.org") }

    before { sign_in guest }

    it "has an empty dashboard" do
      visit hyrax.dashboard_path
      expect(page.has_css?('li.my-actions')).to be true
      expect(find('.user-display-name').text).to eq "nobody@nothing.org"
      expect(page).not_to have_content("Reports")

      visit main_app.fulcrum_path
      expect(page).to have_content "The press \"fulcrum\" doesn't exist!"
    end
  end

  context 'a user a.k.a. user in the user table' do
    let(:user) { create(:user) }

    before { sign_in user }

    it "has an empty dashboard" do
      visit hyrax.dashboard_path
      expect(page.has_css?('li.my-actions')).to be true
      expect(find('.user-display-name').text).to eq user.email
      expect(page).not_to have_content("Reports")

      visit main_app.fulcrum_path
      expect(page).to have_content "The press \"fulcrum\" doesn't exist!"
    end
  end

  context "a press_admin user" do
    let(:a_press) { create(:press, subdomain: 'kitty', name: 'Kitty U', google_analytics_url: 'https://commons.wikimedia.org/wiki/File:Stray_kitten_Rambo002.jpg#/media/File:Stray_kitten_Rambo002.jpg') }
    let(:b_press) { create(:press, subdomain: 'puppy', name: 'Puppy College', google_analytics_url: 'https://commons.wikimedia.org/wiki/File:Puppy_on_a_plastic_lid.jpg#/media/File:Puppy_on_a_plastic_lid.jpg') }
    let(:c_press) { create(:press, subdomain: 'snail', name: 'Snail School',  google_analytics_url: 'https://commons.wikimedia.org/wiki/File:Snail2.JPG#/media/File:Snail2.JPG') }
    let(:press_admin) { create(:press_admin) }

    before do
      Role.create!(resource_type: 'Press', resource_id: a_press.id, user_id: press_admin.id, role: 'admin')
      Role.create!(resource_type: 'Press', resource_id: b_press.id, user_id: press_admin.id, role: 'admin')
      sign_in press_admin
    end

    it "has no fulcrum dashboard" do
      visit main_app.fulcrum_path
      expect(page).to have_content "The press \"fulcrum\" doesn't exist!"
    end

    it "has a hyrax dashboard with reports for only their presses" do
      visit hyrax.dashboard_path
      click_on 'Reports'
      click_on 'Google Analytics'
      # visit '/admin/stats?partial=analytics'

      expect(find('#publisher_report')).to have_content("Kitty U")
      expect(find('#publisher_report')).to have_content("Puppy College")
      expect(find('#publisher_report')).not_to have_content("Snail School")
    end
  end

  context "a platform_admin user" do
    let(:platform_admin) { create(:platform_admin) }

    before { sign_in platform_admin }

    it "has access to both dashboards" do
      visit main_app.fulcrum_path
      expect(page).to have_content 'Dashboard'

      visit hyrax.dashboard_path
      expect(page.has_css?('li.my-actions')).to be true
      expect(find('.user-display-name').text).to eq platform_admin.email
      expect(page).to have_content("Reports")
    end
  end

  def take_failed_screenshot
    false
  end
end
