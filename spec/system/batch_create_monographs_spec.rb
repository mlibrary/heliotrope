# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Batch creation of monographs', type: :system do
  let(:user) { create(:press_admin) }
  let(:users_press) { user.presses.first }
  let(:other_press) { create(:press) }

  before do
    stub_out_redis
    # Batch create sends the audit user a message. If this user is not found there will be an error stating:
    # `ActiveModel::UnknownAttributeError: unknown attribute 'password' for User.`
    allow(Hyrax.config).to receive(:audit_user_key).and_return(user.email)
    cosign_login_as user
    visit hyrax.new_batch_upload_path payload_concern: 'Monograph'
  end

  it "allows monograph creation by batch" do
    expect(Monograph.count).to eq(0)

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

    check('agreement') # Deposit Agreement
    choose('batch_upload_item_visibility_open') # Visibility (not strictly necessary to pass this test)

    click_link "Descriptions" # switch tab
    expect(page).to have_text(users_press.name)
    # you can't select a press for which you're not an admin
    expect(page).not_to have_text(other_press.name)
    expect(page).to have_select('batch_upload_item_press', options: ['', users_press.name])
    select users_press.name, from: 'batch_upload_item_press'

    click_on('Save')

    expect(Monograph.count).to eq(2)

    # should be on the dashboard "Works" page post-save, but to be sure...
    click_link 'Works'
    # The new monographs are titled with the filenames
    expect(page).to have_content 'shipwreck.jpg'
    expect(page).to have_content 'miranda.jpg'
  end
end
