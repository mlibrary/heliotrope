require 'rails_helper'

feature 'Edit a section' do
  context 'a logged in user' do
    before do
      Section.destroy_all
      Monograph.destroy_all
    end
    let(:user) { create(:platform_admin) }
    let!(:monograph1) { create(:monograph, user: user) }
    let!(:monograph2) { create(:monograph, user: user) }
    let!(:monograph3) { create(:monograph, user: user) }
    let!(:section) { create(:section, monograph_id: monograph2.id) }
    before do
      login_as user
    end

    scenario "the section's monograph is pre-selected in the monograph dropdown" do
      visit edit_curation_concerns_section_path(section.id)
      selected = find("select#section_monograph_id option[value='#{monograph2.id}']")
      expect(selected).to be_selected
    end
  end
end
