require 'rails_helper'

feature "Show a monograph with attached sections" do
  let(:user) { create(:user) }

  let(:last_name) { 'Shakespeare' }
  let(:first_name) { 'William' }

  let!(:monograph) { create(:monograph, user: user, creator_family_name: last_name, creator_given_name: first_name) }
  let!(:section) { create(:section, title: ['Chapter 1'], user: user) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  before do
    monograph.ordered_members << section
    monograph.save!
    login_as user
  end

  scenario do
    visit monograph_show_path(monograph)

    expect(page).to have_link 'Chapter 1'
    expect(page).to have_link 'Shakespeare, William'
  end
end
