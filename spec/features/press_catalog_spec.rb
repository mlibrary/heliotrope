require 'rails_helper'

feature 'Press Catalog' do
  before { Press.destroy_all }

  let(:umich) { create(:press, subdomain: 'umich') }
  let(:psu) { create(:press, subdomain: 'psu') }

  context 'a user who is not logged in' do
    context 'with monographs for different presses' do
      let!(:red) { create(:public_monograph, title: ['The Red Book'], press: umich.subdomain) }
      let!(:blue) { create(:public_monograph, title: ['The Blue Book'], press: umich.subdomain) }
      let!(:colors) { create(:public_monograph, title: ['Red and Blue are Colors'], press: psu.subdomain) }

      scenario 'visits the catalog page for a press' do
        # jmcglone: disabling the main catalog test because we won't launch with this.
        # TODO: reenable this test once we bring back the main catalog search
        # The main catalog
        # visit search_catalog_path

        # I should see all the public monographs
        # expect(page).to have_selector('#documents .document', count: 3)
        # expect(page).to have_link red.title.first
        # expect(page).to have_link blue.title.first
        # expect(page).to have_link colors.title.first

        # Search the catalog
        # fill_in 'q', with: 'Red'
        # click_button 'Search'

        # I should see search results from all presses
        # expect(page).to have_selector('#documents .document', count: 2)
        # expect(page).to     have_link red.title.first
        # expect(page).to_not have_link blue.title.first
        # expect(page).to     have_link colors.title.first

        # The catalog for a certain press
        visit Rails.application.routes.url_helpers.press_catalog_path(umich)

        # I should see only the public monographs for this press
        expect(page).to have_selector('#documents .document', count: 2)
        expect(page).to     have_link red.title.first
        expect(page).to     have_link blue.title.first
        expect(page).to_not have_link colors.title.first

        # Search within this press catalog
        fill_in 'q', with: 'Red'
        click_button 'Search'

        # I should see search results for only this press
        expect(page).to have_selector('#documents .document', count: 1)
        expect(page).to     have_link red.title.first
        expect(page).to_not have_link blue.title.first
        expect(page).to_not have_link colors.title.first
      end
    end
    context 'with with a monograph with multiple authors' do
      let!(:monograph) { create(:public_monograph, title: ['The Two Authors\' Book'], creator_family_name: 'Johns', creator_given_name: 'Jimmy', contributor: ['Sub Way'], press: umich.subdomain) }

      scenario 'Sees multiple author names on the press catalog page' do
        visit Rails.application.routes.url_helpers.press_catalog_path(umich)
        expect(page).to have_content 'Jimmy Johns and Sub Way'
      end
    end
  end # not logged in
end
