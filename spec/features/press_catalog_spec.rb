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

    context 'with with a monograph with multiple authors' do
      let!(:monograph) { create(:public_monograph, title: ['The Two Authors\' Book'], creator_family_name: 'Johns', creator_given_name: 'Jimmy', contributor: ['Sub Way'], press: umich.subdomain) }

      scenario 'Sees multiple author names on the press catalog page' do
        visit "/#{umich.subdomain}"
        expect(page).to have_content 'Jimmy Johns and Sub Way'
      end
    end
    # Because Hyrax now uses system_create (which is non-modifiable in Fedora) as the uploaded_field, we can't easily...
    # set the uploaded_field in specs. Two 1-second sleeps ensure these monographs have different uploaded_fields, as...
    # the time granularity is one second. FYI it used to be date_uploaded, which we could set as we pleased.
    # TODO: (possibly) maybe rewrite this in a view test like this one
    # https://github.com/samvera/hyrax/blob/master/spec/views/hyrax/collections/_form_for_select_collection.html.erb_spec.rb
    context 'monograph sort order is uploaded_field desc' do
      before do
        create(:press, subdomain: 'sort_press')
        create(:public_monograph, press: 'sort_press', title: ['First Created'])
        sleep 1.second
        create(:public_monograph, press: 'sort_press', title: ['Second Created'])
        sleep 1.second
        create(:public_monograph, press: 'sort_press', title: ['Third Created'])
      end
      scenario "shows the monographs in reverse order of date_uploaded" do
        visit "/sort_press"
        assert_equal page.all('.documentHeader .index_title a').collect(&:text), ['Third Created',
                                                                                  'Second Created',
                                                                                  'First Created']
      end
    end
  end # not logged in
end
