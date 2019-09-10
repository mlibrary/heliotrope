# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Cozy Sun Bear", type: :system do
  let(:user) { create(:platform_admin) }
  let(:press) { create(:press, subdomain: 'blue') }
  let(:monograph) { create(:monograph, press: press.subdomain, user: user, visibility: "open", representative_id: cover.id) }
  let(:cover) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }
  let(:file_set) { create(:file_set, id: '999999999', allow_download: 'yes', content: File.open(File.join(fixture_path, 'fake_epub01.epub'))) }
  let!(:fr) { create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

  before do
    sign_in user
    stub_out_redis
    monograph.ordered_members << cover
    monograph.ordered_members << file_set
    monograph.save!
    cover.save!
    file_set.save!
    UnpackJob.perform_now(file_set.id, 'epub')
  end

  it "clicking on a chapter link takes you to the correct chapter in CSB" do
    visit monograph_catalog_path(monograph)
    # should have an epub download button for the platform_admin
    click_button "Download"
    expect(page).to have_content("EPUB (#{ActiveSupport::NumberHelper.number_to_human_size(file_set.file_size.first)})")

    expect(page).to have_link "Shields up!"
    # Clicking on chapter 2 in the ToC
    click_on "Shields up!"
    # Takes you to chapter 2 in CSB
    # Don't `sleep` to wait for CSB to load everything, instead have a test that
    # needs something CSB creates. Capybara will handle the rest.
    expect(page).to have_selector('iframe')
    # expect(page).to have_content "some content" doesn't work with CSB, I think it's
    # because of the iframe. This works though:
    expect(page.body.match?(/communal imprints on the universe more possible, as they offer two-player, networked, or online modes/)).to be true
  end
end
