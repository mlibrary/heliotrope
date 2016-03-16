require 'rails_helper'

feature "Show a monograph with attached sections" do
  let(:user) { create(:user) }
  let!(:monograph) { create(:monograph, user: user) }
  let!(:section) { create(:section, title: ['Chapter 1'], user: user) }
  before do
    monograph.ordered_members << section
    monograph.save!
    login_as user
  end

  scenario do
    visit curation_concerns_monograph_path(monograph)

    expect(page).to have_link 'Chapter 1'
  end
end
