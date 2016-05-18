require 'rails_helper'

feature "Show a monograph with attached sections" do
  let(:user) { create(:user) }

  let(:last_name) { 'Shakespeare' }
  let(:first_name) { 'William' }

  let!(:monograph) { create(:monograph, user: user, creator_family_name: last_name, creator_given_name: first_name) }
  let!(:section) { create(:section, title: ['Chapter 1'], user: user) }

  before do
    monograph.ordered_members << section
    monograph.save!
    login_as user
  end

  scenario do
    visit curation_concerns_monograph_path(monograph)

    expect(page).to have_link 'Chapter 1'
    expect(page).to have_link 'Shakespeare, William'
  end
end
