require 'rails_helper'

feature 'Display a section' do
  let(:user) { create(:user) }
  let!(:monograph) { create(:monograph, user: user) }
  let!(:ch2) { create(:section, title: ['Chapter 2'], user: user) }
  let!(:ch1) { create(:section, title: ['Chapter 1'], user: user) }

  let(:admin_user) { create(:platform_admin) }
  let!(:unauthorized_section) { create(:section, user: admin_user) }

  before do
    monograph.ordered_members = [ch1, ch2]
    monograph.save!
    login_as user
  end

  scenario 'for a monograph with several sections' do
    visit monograph_show_path(monograph)

    expect(page).to have_link 'Chapter 1'
    expect(page).to have_link 'Chapter 2'

    click_on 'Chapter 1'
    expect(page).to have_content 'Chapter 1'

    visit monograph_show_path(monograph)
    click_on 'Chapter 2'
    expect(page).to have_content 'Chapter 2'
  end

  # bugfix #129
  scenario "when a section is private, display an unauthorized message to unauthorized users" do
    visit curation_concerns_section_path(unauthorized_section)

    expect(page).to have_content "Unauthorized"
  end
end
