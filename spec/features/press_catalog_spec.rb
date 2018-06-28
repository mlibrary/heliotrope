# frozen_string_literal: true

require 'rails_helper'

feature 'Press Catalog' do
  before { Press.destroy_all }

  let(:umich) { create(:press, subdomain: 'umich') }
  let(:psu) { create(:press, subdomain: 'psu') }
  let(:heb) { create(:press, subdomain: 'heb') }

  context 'a user who is not logged in' do
    context 'with monographs for different presses' do
      let!(:red) { create(:public_monograph, title: ['The Red Book'], press: umich.subdomain) }
      let!(:blue) { create(:public_monograph, title: ['The Blue Book'], press: umich.subdomain) }
      let!(:invisible) { create(:private_monograph, title: ['The Invisible Book'], press: umich.subdomain) }
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
        expect(page).to_not have_link invisible.title.first
        expect(page).to_not have_link colors.title.first

        # Search within this press catalog
        fill_in 'q', with: 'Red'
        click_button 'Search'

        # I should see search results for only this press
        expect(page).to have_selector('#documents .document', count: 1)
        expect(page).to     have_link red.title.first
        expect(page).to_not have_link blue.title.first
        expect(page).to_not have_link invisible.title.first
        expect(page).to_not have_link colors.title.first

        expect(page).to have_link("View book materials", href: monograph_catalog_path(red, locale: 'en'))
        # thumbnail link
        expect(page).to have_selector("img[alt='Cover image for #{red.title[0]}']")
        expect(page).to have_link('', href: monograph_catalog_path(red, locale: 'en'))

        # Selectors needed for assets/javascripts/ga_event_tracking.js
        # If these change, fix here then update ga_event_tracking.js
        expect(page).to have_selector('a.navbar-brand')
        expect(page).to have_selector('#documents .document h3.index_title a')
        expect(page).to have_selector('#documents .document a.btn.btn-default')
        expect(page).to have_selector('footer.press a')
        expect(page).to have_selector('#keyword-search-submit')
        expect(page).to have_selector('#catalog_search')
      end

      scenario 'visits the catalog page for a press with the press name capitalized' do
        visit "/#{umich.subdomain.upcase}"
        # I should see only the public monographs for this press
        expect(page).to have_selector('#documents .document', count: 2)
        expect(page).to     have_link red.title.first
        expect(page).to     have_link blue.title.first
        expect(page).to_not have_link invisible.title.first
        expect(page).to_not have_link colors.title.first
      end

      context 'with a press that also has "child presses"' do
        let(:umich_child_1) { create(:press, subdomain: 'umich_child_1', parent_id: umich.id) }
        let(:umich_child_2) { create(:press, subdomain: 'umich_child_2', parent_id: umich.id) }
        let(:psu_child) { create(:press, subdomain: 'psu_child', parent_id: psu.id) }
        let!(:purple) { create(:public_monograph, title: ['The Purple Book'], press: umich_child_1.subdomain) }
        let!(:green) { create(:public_monograph, title: ['The Green Book'], press: umich_child_2.subdomain) }
        let!(:hues) { create(:public_monograph, title: ['Purple and Green be Hues'], press: psu_child.subdomain) }

        scenario 'visits the catalog page for a press' do
          visit "/#{umich.subdomain}"
          # I should see only the public monographs for umich press and its children
          expect(page).to have_selector('#documents .document', count: 4)
          expect(page).to     have_link red.title.first
          expect(page).to     have_link blue.title.first
          expect(page).to_not have_link invisible.title.first
          expect(page).to     have_link purple.title.first
          expect(page).to     have_link green.title.first
          expect(page).to_not have_link colors.title.first
          expect(page).to_not have_link hues.title.first
        end
      end
    end

    context 'with a monograph with multiple authors' do
      let!(:monograph) { create(:public_monograph,
                                title: ['The Two Authors\' Book'],
                                creator: ['Johns, Jimmy (a role)'],
                                contributor: ['Way, Sub (another role)'],
                                press: umich.subdomain) }

      scenario 'sees multiple author names on the press catalog page' do
        visit "/#{umich.subdomain}"
        expect(page).to have_content 'Jimmy Johns and Sub Way'
      end
    end

    context 'with a monograph with multiple authors in HEB-style format' do
      let!(:monograph) { create(:public_monograph,
                                title: ['The Three Authors\' Book'],
                                creator: ["Johns, Jimmy, 1888-1968 (a role)\nAuthor, Second"],
                                contributor: ['Way, Sub (another role)'],
                                press: heb.subdomain) }

      scenario 'sees multiple "reversed" author names on the press catalog page, retaining birth/death years' do
        visit "/#{heb.subdomain}"
        expect(page).to have_content 'Johns, Jimmy, 1888-1968; Author, Second; Way, Sub'
      end
    end

    context 'monograph sort order is title asc' do
      before do
        create(:press, subdomain: 'sort_press')
        create(:public_monograph, press: 'sort_press', title: ['silverfish'])
        create(:public_monograph, press: 'sort_press', title: ['Cormorant'])
        create(:public_monograph, press: 'sort_press', title: ['Zebra'])
        create(:public_monograph, press: 'sort_press', title: ['aardvark'])
        create(:public_monograph, press: 'sort_press', title: ['Manatee'])
        create(:public_monograph, press: 'sort_press', title: ['baboon'])
      end
      scenario "shows the monographs in reverse order of date_uploaded" do
        visit "/sort_press"
        assert_equal page.all('.documentHeader .index_title a').collect(&:text), ['aardvark',
                                                                                  'baboon',
                                                                                  'Cormorant',
                                                                                  'Manatee',
                                                                                  'silverfish',
                                                                                  'Zebra']
      end
    end
  end # not logged in
end
