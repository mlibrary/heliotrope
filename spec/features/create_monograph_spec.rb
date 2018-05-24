# frozen_string_literal: true

require 'rails_helper'

feature 'Create a monograph' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }
    let!(:press) { create(:press) }

    before do
      cosign_login_as user
      stub_out_redis
    end

    scenario do
      visit new_hyrax_monograph_path

      # Monograph form
      # Basic Metadata
      fill_in 'monograph[title]', with: 'Test monograph'
      select press.name, from: 'Publisher'
      fill_in 'Description', with: 'Blahdy blah description works'
      expect(page).to have_css('input.monograph_subject', count: 1)
      fill_in 'Subject', with: 'red stuff'
      expect(page).to have_css('input.monograph_language', count: 1)
      fill_in 'Language', with: 'English'
      fill_in 'Section Titles', with: 'Intro\nChapter 1\nChapter 2'
      fill_in 'Buy Book URL(s)', with: 'http://www.example.com/buy'
      fill_in 'Copyright Holder', with: 'Blahdy Blah Copyright Holder'
      fill_in 'Holding Contact', with: 'http://www.blahpresscompany.com/'

      # Authorship Metadata
      # # 'Authors' is ambiguous
      fill_in 'monograph[creator]', with: "Johns, Jimmy\nWay, Sub (editor)"
      fill_in 'Additional Authors', with: 'Shoppe, Sandwich (another unused role)'

      # Citation Metadata
      # publisher
      fill_in 'Publisher', with: 'Blah Press, Co.'
      # date_created
      fill_in 'Publication Year', with: '2001'
      # location
      fill_in 'Publication Location', with: 'Ann Arbor, MI.'
      # ISBNs
      fill_in 'ISBN (Hardcover)', with: '123-456-7890'
      fill_in 'ISBN (Paper)', with: '123-456-7891'
      fill_in 'ISBN (E-Book)', with: '123-456-7892'

      # Citable Links
      fill_in 'DOI', with: 'http://wwww.example.com'
      fill_in 'Identifier', with: 'http://www.one-of-many-permanent-urls-for-this.com'

      click_button 'Save'

      # Monograph catalog page
      expect(page).to have_content 'Test monograph'
      expect(page).to have_content press.name
      expect(page).to have_content 'Blahdy blah description works'
      expect(page).to have_content "Jimmy Johns, Sub Way and Sandwich Shoppe"
      expect(page).to have_field('Citable Link', with: 'http://wwww.example.com')
      expect(page).to have_content '123-456-7890'
      expect(page).to have_content '123-456-7891'
      expect(page).to have_content '123-456-7892'
      expect(page).to have_content "Your files are being processed by Fulcrum in the background."

      click_link 'Edit Monograph'

      # back on Monograph form
      # add citation_display to test authorship override
      fill_in 'Authorship Display (free-form text)', with: 'Fancy Authorship Name Stuff That Takes Precedence'
      expect(page).to have_css('input.monograph_subject', count: 2)
      page.all(:fillable_field, 'monograph[subject][]').last.set('green stuff')
      expect(page).to have_css('input.monograph_language', count: 2)
      page.all(:fillable_field, 'monograph[language][]').last.set('German')

      click_button 'Save'

      # back on Monograph catalog page
      # check authorship override
      expect(page).to have_content "Fancy Authorship Name Stuff That Takes Precedence"
      expect(page).to_not have_content "Jimmy Johns, Sub Way and Shoppe Sandwich"
      click_link 'Manage Monograph and Files'

      # On Monograph show page

      # Basic Metadata
      # title
      expect(page).to have_content 'Test monograph'
      # press
      expect(page).to have_content press.name
      # description
      expect(page).to have_content 'Blahdy blah description works'
      # subject
      expect(page).to have_content 'red stuff'
      expect(page).to have_content 'green stuff'
      # language
      expect(page).to have_content 'English'
      expect(page).to have_content 'German'
      # section_titles
      expect(page).to have_content 'Intro\nChapter 1\nChapter 2'
      # buy_url
      expect(page).to have_content 'http://www.example.com/buy'
      # copyright_holder
      expect(page).to have_content 'Blahdy Blah Copyright Holder'
      # holding_contact
      expect(page).to have_content 'http://www.blahpresscompany.com/'

      # Citation Metadata
      # publisher
      expect(page).to have_content 'Blah Press, Co.'
      # date_created
      expect(page).to have_content '2001'
      expect(page).to have_content 'Ann Arbor, MI.'

      # ISBN
      expect(page).to have_content '123-456-7890'
      expect(page).to have_content '123-456-7891'
      expect(page).to have_content '123-456-7892'

      # DOI
      expect(page).to have_content 'http://wwww.example.com'
      # identifier
      expect(page).to have_content 'http://www.one-of-many-permanent-urls-for-this.com'

      # MLA citation
      expect(page).to have_content 'Johns, Jimmy, and Sub Way. Test Monograph. Ann Arbor, MI.'
      # APA citation
      expect(page).to have_content 'Johns, J., & Way, S. (2001). Test monograph. Ann Arbor, MI.: Blah Press, Co.'
      # Chicago citation
      expect(page).to have_content 'Johns, Jimmy, and Sub Way. 2001. Test Monograph. Ann Arbor, MI.: Blah Press, Co.'
    end
  end
end
