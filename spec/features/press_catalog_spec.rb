# frozen_string_literal: true

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
        visit "/#{umich.subdomain}"

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

        expect(page).to have_link("View book materials", href: monograph_catalog_path(red, locale: 'en'))
        # thumbnail link
        expect(page).to have_selector("img[alt='#{red.title[0]}']")
        expect(page).to have_link('', href: monograph_catalog_path(red, locale: 'en'))

        # Selectors needed for assets/javascripts/ga_event_tracking.js
        # If these change, fix here then update ga_event_tracking.js
        expect(page).to have_selector('a.navbar-brand')
        expect(page).to have_selector('#documents .document h2.index_title a')
        expect(page).to have_selector('#documents .document a.btn.btn-default')
        expect(page).to have_selector('footer.press a')
        expect(page).to have_selector('#keyword-search-submit')
        expect(page).to have_selector('#catalog_search')
      end
    end
    context 'with with a monograph with multiple authors' do
      let!(:monograph) { create(:public_monograph, title: ['The Two Authors\' Book'], creator_family_name: 'Johns', creator_given_name: 'Jimmy', contributor: ['Sub Way'], press: umich.subdomain) }

      scenario 'Sees multiple author names on the press catalog page' do
        visit "/#{umich.subdomain}"
        expect(page).to have_content 'Jimmy Johns and Sub Way'
      end
    end
  end # not logged in
end
