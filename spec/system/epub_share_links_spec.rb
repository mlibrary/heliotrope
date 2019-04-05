# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "EPub Share Links", type: :system do
  let(:platform_admin) { create(:platform_admin) }
  let(:press) { create(:press, subdomain: 'blue', share_links: true) }
  let(:monograph) { create(:public_monograph, press: press.subdomain, user: platform_admin, visibility: "open", representative_id: cover.id) }
  let(:cover) { create(:public_file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) { create(:public_file_set, allow_download: 'yes', content: File.open(File.join(fixture_path, 'fake_epub_multi_rendition.epub'))) }
  let(:parent) { Sighrax.factory(monograph.id) }
  let(:epub) { Sighrax.factory(file_set.id) }

  before do
    stub_out_redis
    monograph.ordered_members << cover
    monograph.ordered_members << file_set
    monograph.save!
    cover.save!
    file_set.save!
    FeaturedRepresentative.create!(monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub')
    UnpackJob.perform_now(file_set.id, 'epub')
    Greensub::Component.create!(identifier: parent.resource_token, name: parent.title, noid: parent.noid)
  end

  def take_failed_screenshot
    false
  end

  context "depending on if you are using a share link to access an epub" do
    it "there's an epub download button and share link button, or not" do
      sign_in platform_admin

      # For a platform_admin (or other authed user)
      visit epub_path(id: file_set.id)

      expect(page).to have_content("This is the Title")
      # download epub button is present
      expect(page.has_css?('.cozy-download')).to be true
      # share link button is present
      expect(page).to have_selector('#share-link-btn')
      # click to create a sharable link
      find('#share-link-btn').click

      # If the monograph is open access, do not show a share link
      monograph.open_access = 'yes'
      monograph.save!
      visit epub_path(id: file_set.id)
      # share link button is not present
      expect(page).to have_no_selector('#share-link-btn')

      # set back to no OA and log out
      monograph.open_access = nil
      monograph.save!
      visit presses_path
      within("footer") do
        click_link "Log Out"
      end

      # For an anon user following a share link
      visit epub_path(id: file_set.id, share: ShareLinkLog.last.token)

      expect(page).to have_content("This is the Title")
      # download epub button is not present
      expect(page.has_css?('.cozy-download')).to be false
      # share link button is not present
      expect(page).to have_no_selector('#share-link-btn')
    end
  end
end
