require 'rails_helper'

feature "Monograph Catalog Facets" do
  context "keywords" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, user: user, title: ["Yellow"], representative_id: cover.id) }
    let(:cover) { create(:file_set) }
    let(:file_set1) { create(:file_set, keywords: ["cat", "dog", "elephant", "lizard", "monkey", "mouse", "tiger"]) }
    before do
      login_as user
      monograph.ordered_members << cover
      monograph.ordered_members << file_set1
      monograph.save!
    end
    scenario "shows keywords in the intended order" do
      visit monograph_catalog_facet_path(id: 'keywords_sim', monograph_id: monograph.id)
      expect(page).to have_selector '.facet-values li:first', text: "cat"
    end
  end

  context "sections" do
    let(:user) { create(:platform_admin) }
    let(:monograph) { create(:monograph, user: user, title: ["Yellow"], representative_id: cover.id) }
    let(:cover) { create(:file_set) }
    before do
      login_as user
      stub_out_redis
      monograph.ordered_members << cover
      monograph.save!
    end

    scenario "shows sections in intended order" do
      # Section 1, 1 file
      visit new_curation_concerns_section_path
      fill_in 'Title', with: "C 1"
      select monograph.title.first, from: "Monograph"
      click_button 'Create Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'Section 1 File 1'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      # Section 2, 2 files
      visit new_curation_concerns_section_path
      fill_in 'Title', with: "B 2"
      select monograph.title.first, from: "Monograph"
      click_button 'Create Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'Section 2 File 1'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'Section 2 File 2'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      # Section 3, 3 files
      visit new_curation_concerns_section_path
      fill_in 'Title', with: "A 3"
      select monograph.title.first, from: "Monograph"
      click_button 'Create Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'Section 3 File 1'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'Section 3 File 2'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      click_link 'Attach a File'
      fill_in 'Title', with: 'Section 3 File 3'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      click_button 'Attach to Section'

      visit monograph_catalog_facet_path(id: 'section_title_sim', monograph_id: monograph.id)

      # facet section order should be:
      # "C 1"
      # "B 2"
      # "A 3"
      # so by order, not alphabetically or by frequency

      expect(page).to have_selector '.facet-values li:first', text: "C 1"
      expect(page).to_not have_selector '.facet-values li:first', text: "A 3"
    end
  end
end
