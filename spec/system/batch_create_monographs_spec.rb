# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch creation of monographs', type: :system, browser: true do
  let(:user) { create(:press_admin) }
  let(:users_press) { user.presses.first }
  let(:other_press) { create(:press) }

  before do
    stub_out_redis
    # Considerable work was put into getting basic batch Monograph creation working, but we've never used it as...
    # part of our production workflow. Until we have an actual use case for it, it's disabled in `config/features.yml`.
    # For the sake of keeping this spec running, we'll stub the Flipflop return value.
    allow(Flipflop).to receive(:batch_upload?).and_return(true)
    login_as user
    visit hyrax.new_batch_upload_path payload_concern: 'Monograph'
  end

  it "allows monograph creation by batch" do
    expect(Monograph.count).to eq(0)
    # no audit_user created yet (see below)
    expect(User.count).to eq(1)

    expect(page).to have_content "Add New Monographs by Batch"
    within("li.active") do
      expect(page).to have_content("Files")
    end
    expect(page).to have_content("Each file will be uploaded to a separate new monograph resulting in one monograph per uploaded file.")

    click_link "Files" # switch tab

    expect(page).to have_content "Add files"
    within('span#addfiles') do
      # one monograph should be produced for each of these files
      attach_file("files[]", fixture_path + '/csv/shipwreck.jpg', visible: false)
      attach_file("files[]", fixture_path + '/csv/miranda.jpg', visible: false)
    end

    # HELIO-3094
    expect(page).not_to have_selector '#batch_upload_item_visibility_authenticated' # institutional access
    expect(page).not_to have_selector '#batch_upload_item_visibility_embargo'
    expect(page).not_to have_selector '#batch_upload_item_visibility_lease'

    # check('agreement') # Deposit Agreement, currently disabled in `config/features.yml`
    choose('batch_upload_item_visibility_open') # Visibility (not strictly necessary to pass this test)

    click_link "Descriptions" # switch tab
    expect(page).to have_text(users_press.name)
    # you can't select a press for which you're not an admin
    expect(page).not_to have_text(other_press.name)
    expect(page).to have_select('batch_upload_item_press', options: ['', users_press.name])
    select users_press.name, from: 'batch_upload_item_press'

    click_on('Save')

    expect(Monograph.count).to eq(2)
    # Batch create sends the audit_user a message
    # A User with email (key) of `Hyrax.config.audit_user_key` was created as required by Hyrax::AbstractMessageService
    # see https://tools.lib.umich.edu/jira/browse/HELIO-2065
    expect(User.count).to eq(2)
    expect(User.last.user_key).to eq(Hyrax.config.audit_user_key)

    # should be on the dashboard "Works" page post-save, but to be sure...
    click_link 'Works'
    # The new monographs are titled with the filenames
    expect(page).to have_content 'shipwreck.jpg'
    expect(page).to have_content 'miranda.jpg'
  end
end
