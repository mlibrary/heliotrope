require 'rails_helper'

feature 'Catalog search' do
  context 'a user who is not logged in' do
    let!(:private_monograph) { create(:private_monograph) }
    let!(:public_monograph) { create(:public_monograph) }

    scenario 'visits the catalog page' do
      visit search_catalog_path

      # There should be this many search results total:
      expect(page).to have_selector('#documents .document', count: 1)

      expect(page).to have_link public_monograph.title.first
      expect(page).not_to have_link private_monograph.title.first
    end
  end
end
