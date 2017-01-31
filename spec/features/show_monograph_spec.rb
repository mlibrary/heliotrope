require 'rails_helper'

feature "Show a monograph" do
  let(:last_name) { 'Shakespeare' }
  let(:first_name) { 'William' }

  let!(:monograph) { create(:public_monograph, creator_family_name: last_name, creator_given_name: first_name) }

  scenario do
    visit monograph_show_path(monograph)
    expect(page).to have_link 'Shakespeare, William'
  end
end
