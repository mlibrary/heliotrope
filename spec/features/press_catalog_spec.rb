# frozen_string_literal: true

require 'rails_helper'

describe 'Press Catalog' do
  before { Press.destroy_all }

  let(:umich) { create(:press, subdomain: 'umich') }
  let(:psu) { create(:press, subdomain: 'psu') }
  let(:heb) { create(:press, subdomain: 'heb') }

  context 'a user who is not logged in' do
    context 'with monographs for different presses' do
      let(:red_cover_alt_text) { ["The Red Book"] }
      let(:red_cover) { create(:public_file_set, alt_text: red_cover_alt_text) }
      let!(:red) { create(:public_monograph, title: ['The Red Book'], representative_id: red_cover.id, press: umich.subdomain) }
      let!(:blue) { create(:public_monograph, title: ['The Blue Book'], press: umich.subdomain) }
      let!(:invisible) { create(:private_monograph, title: ['The Invisible Book'], press: umich.subdomain) }
      let!(:colors) { create(:public_monograph, title: ['Red and Blue are Colors'], press: psu.subdomain) }

      it 'visits the catalog page for a press' do
        # The catalog for a certain press
        visit "/#{umich.subdomain}"
        expect(page).to_not have_content("Your search has returned")

        # I should see only the public monographs for this press
        expect(page).to have_selector('#documents .document', count: 2)
        expect(page).to     have_link red.title.first
        expect(page).to     have_link blue.title.first
        expect(page).not_to have_link invisible.title.first
        expect(page).not_to have_link colors.title.first

        # The Press Catalog is *always* gallery view
        expect(page).to have_selector('#documents.row.gallery')

        # Since this is not a search, it's a "browse" and the default
        # sort should be Sort by Date Added (Newest First)
        expect(page).to have_content "Sort by Date Added (Newest First)"

        # Presses with less than 15 books will not have facets
        expect(page).not_to have_selector(".facets-container")

        # Search within this press catalog
        fill_in 'q', with: 'Red'
        click_button 'Search'

        # Search results have a default sort of Relevance
        expect(page).to have_content "Sort by Relevance"

        # I should see search results for only this press
        expect(page).to have_selector('#documents .document', count: 1)
        expect(page).to have_content("Your search has returned 1 book from #{umich.name}")
        expect(page).to     have_link red.title.first
        expect(page).not_to have_link blue.title.first
        expect(page).not_to have_link invisible.title.first
        expect(page).not_to have_link colors.title.first

        # thumbnail link
        expect(page).to have_selector("img[alt='']")
        expect(page).to have_link('', href: monograph_catalog_path(red, locale: 'en'))

        # Selectors needed for assets/javascripts/application/ga_event_tracking.js
        # If these change, fix here then update ga_event_tracking.js
        expect(page).to have_selector('a.navbar-brand')
        expect(page).to have_selector('#documents .document a')
        expect(page).to have_selector('footer.press a')
        expect(page).to have_selector('#keyword-search-submit')
        expect(page).to have_selector('#catalog_search')
      end

      it 'visits the catalog page for a press with the press name capitalized' do
        visit "/#{umich.subdomain.upcase}"
        # I should see only the public monographs for this press
        expect(page).to have_selector('#documents .document', count: 2)
        expect(page).to_not have_content("Your search has returned")
        expect(page).to     have_link red.title.first
        expect(page).to     have_link blue.title.first
        expect(page).not_to have_link invisible.title.first
        expect(page).not_to have_link colors.title.first
      end

      context 'with a press that also has "child presses"' do
        let(:umichchild1) { create(:press, subdomain: 'umichchild1', parent_id: umich.id) }
        let(:umichchild2) { create(:press, subdomain: 'umichchild2', parent_id: umich.id) }
        let(:psuchild) { create(:press, subdomain: 'psuchild', parent_id: psu.id) }
        let!(:purple) { create(:public_monograph, title: ['The Purple Book'], press: umichchild1.subdomain) }
        let!(:green) { create(:public_monograph, title: ['The Green Book'], press: umichchild2.subdomain) }
        let!(:hues) { create(:public_monograph, title: ['Purple and Green be Hues'], press: psuchild.subdomain) }

        it 'visits the catalog page for a press' do
          visit "/#{umich.subdomain}"
          # I should see only the public monographs for umich press and its children
          expect(page).to have_selector('#documents .document', count: 4)
          expect(page).to_not have_content("Your search has returned")
          expect(page).to     have_link red.title.first
          expect(page).to     have_link blue.title.first
          expect(page).not_to have_link invisible.title.first
          expect(page).to     have_link purple.title.first
          expect(page).to     have_link green.title.first
          expect(page).not_to have_link colors.title.first
          expect(page).not_to have_link hues.title.first
        end
      end
    end

    context 'with a monograph with multiple authors' do
      let!(:monograph) {
        create(:public_monograph,
               title: ['The Two Authors\' Book'],
               creator: ['Johns, Jimmy (a role)'],
               contributor: ['Way, Sub (another role)'],
               press: umich.subdomain)
      }

      it 'sees multiple author names on the press catalog page' do
        visit "/#{umich.subdomain}"
        expect(page).to have_content 'Jimmy Johns and Sub Way'
      end
    end

    context 'with a press with 9 or more open monographs' do
      before do
        10.times do |n|
          title = Faker::Book.title
          name1 = Faker::Book.author
          open_access = nil

          # give 3 of the books a second creator, for a total of 16 + 3 = 19 creators
          if [3, 6, 9].include? n
            name2 = Faker::Book.author
            creators = [name1, name2]
            open_access = 'yes' # also make these open access to test that facet
          else
            creators = name1
          end

          date = Faker::Time.between(DateTime.now - 9999, DateTime.now)
          doc = ::SolrDocument.new(
            id: Random.rand(999_999_999),
            has_model_ssim: 'Monograph',
            press_sim: "heb",
            read_access_group_ssim: "public",
            title_tesim: title,
            title_si: title,
            creator_tesim: creators,
            creator_sim: creators, # facetable
            creator_full_name_si: name1,
            date_created_si: date.year,
            date_uploaded_dtsi: date,
            subject_sim: Faker::Pokemon.name,
            publisher_sim: Faker::Book.publisher,
            open_access_sim: open_access, # facetable
            suppressed_bsi: false,
            visibility_ssi: 'open'
          )
          ActiveFedora::SolrService.add(doc.to_h)
        end
        ActiveFedora::SolrService.commit
      end

      it 'the press catalog page has facets' do
        visit "/#{heb.subdomain}"
        expect(page.title).to eq heb.name

        # Presses with 15 or more books will have facets,
        # less than 15 don't
        expect(page).to have_selector(".facets-container")

        expect(page).to have_link "Publisher"
        expect(page).to have_selector("#facet-publisher_sim")
        # expect(page).to have_selector("#facet-open_access_sim")
        # use "fake facet" Access (user_access) instead of OA, # HELIO-3347
        expect(page).to have_selector('#facet-user_access')

        expect(page).to have_selector('#facet-creator_sim a.facet_select', count: 5) # 5 is limit in facet widget

        # dedicated facet modal shows up to 20 values, we expect 13 creator names
        find("a[href='/#{heb.subdomain}/facet?id=creator_sim&locale=en']").click
        # save_and_open_page
        expect(page).to have_selector('a.facet-anchor.facet_select', count: 13)

        find('a.facet-anchor.facet_select', match: :first).click
        expect(page.title).to eq "#{heb.name} results - page 1 of 1"
        expect(page).to have_selector('#documents .document', count: 1)
        expect(page).to have_content("Your search has returned 1 book from #{heb.name}")
      end
    end
  end # not logged in
end
