# frozen_string_literal: true

require 'rails_helper'

describe "Show a monograph" do
  let(:creator) { ['Shakespeare, William'] }
  let(:first_name) { 'William' }
  let(:user) { create(:platform_admin) }

  let!(:draft_monograph) { create(:monograph, creator: creator) }
  let!(:draft_file_set) { create(:file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }

  let!(:public_monograph) { create(:public_monograph, creator: creator) }
  let!(:public_file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'csv', 'miranda.jpg'))) }

  let(:today) { Time.zone.now.strftime "%Y-%m-%d" }

  before do
    draft_monograph.ordered_members << draft_file_set
    draft_monograph.save
    draft_file_set.save

    public_monograph.ordered_members << public_file_set
    public_monograph.save
    public_file_set.save

    login_as user
  end

  it 'draft monograph stuff' do
    visit monograph_show_path(draft_monograph)
    expect(page).to have_link 'Shakespeare, William'
    expect(page).to have_content "Date Uploaded\n#{today}"
    expect(page).not_to have_content "Date Published on Fulcrum\n#{today}"
    expect(page).to have_content "Last Modified\n#{today}"

    # this assertion to prevent recurrence of HELIO-4568 fiasco
    click_link "Download #{draft_file_set.title.first}"
    expect(page).to have_http_status(:success)
  end

  it 'public monograph stuff' do
    visit monograph_show_path(public_monograph)
    expect(page).to have_link 'Shakespeare, William'
    expect(page).to have_content "Date Uploaded\n#{today}"
    expect(page).to have_content "Date Published on Fulcrum\n#{today}"
    expect(page).to have_content "Last Modified\n#{today}"

    click_link "Download #{public_file_set.title.first}"
    expect(page).to have_http_status(:success)
  end
end
