# frozen_string_literal: true

require 'rails_helper'

feature 'Sign In Out' do
  context "from /" do
    let!(:user) { create(:platform_admin, email: "ferg@example.com") }

    scenario "login in goes to /dashboard" do
      visit new_user_session_path

      fill_in 'Email', with: 'ferg@example.com'
      click_button 'Save'

      expect(page).to have_current_path(hyrax.dashboard_path(locale: 'en'))
    end
  end

  context "when logged in and on the /dashboard page" do
    let!(:user) { create(:platform_admin, email: "ferg@example.com") }

    before do
      cosign_login_as user
    end

    scenario "logout goes to /" do
      visit(hyrax.dashboard_path)

      click_link "Log Out"

      expect(page).to have_current_path(main_app.root_path(locale: 'en'))
    end
  end

  context "on an asset page" do
    let(:user) { create(:platform_admin, email: "ferg@example.com") }
    let(:cover) { create(:file_set) }
    let(:file_set) { create(:public_file_set, user: user, title: ["Blue"]) }
    let!(:monograph) do
      m = build(:monograph, title: ['Yellow'],
                            representative_id: cover.id)
      m.ordered_members = [cover, file_set]
      m.save!
      m
    end

    let(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
    end

    before do
      stub_out_redis
      file_set.update_index
    end

    scenario "logging in goes to that asset page" do
      visit hyrax_file_set_path(file_set)

      click_link "Log In"
      fill_in 'Email', with: 'ferg@example.com'
      click_button 'Save'

      expect(page).to have_current_path(hyrax_file_set_path(file_set))
    end

    scenario "logging out goes to that asset page" do
      cosign_login_as user
      visit hyrax_file_set_path(file_set)

      within("footer") do
        click_link "Log Out"
      end

      expect(page).to have_current_path(hyrax_file_set_path(file_set))
    end
  end
end
