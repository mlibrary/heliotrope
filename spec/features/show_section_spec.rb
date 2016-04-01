require 'rails_helper'

feature 'Display a section' do
  let(:user) { create(:user) }
  let!(:monograph) { create(:monograph, user: user) }
  let!(:ch2) { create(:section, title: ['Chapter 2'], user: user) }
  let!(:ch1) { create(:section, title: ['Chapter 1'], user: user) }

  before do
    monograph.ordered_members = [ch1, ch2]
    monograph.save!
    login_as user
  end

  scenario 'for a monograph with several sections' do
    visit curation_concerns_monograph_path(monograph)

    expect(page).to have_link 'Chapter 1'
    expect(page).to have_link 'Chapter 2'

    click_on 'Chapter 1'
    expect(page).to have_content 'Chapter 1'

    visit curation_concerns_monograph_path(monograph)
    click_on 'Chapter 2'
    expect(page).to have_content 'Chapter 2'
  end
end
