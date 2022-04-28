# frozen_string_literal: true

require 'rails_helper'

describe 'Create a monograph' do
  context 'a logged in user' do
    let(:user) { create(:platform_admin) }
    let!(:press) { create(:press) }

    before do
      login_as user
      stub_out_redis
      stub_out_irus
    end

    it do # rubocop:disable RSpec/ExampleLength
      visit new_hyrax_monograph_path

      # Monograph form

      # HELIO-3094
      expect(page).not_to have_selector '#monograph_visibility_authenticated' # institutional access
      expect(page).not_to have_selector '#monograph_visibility_embargo'
      expect(page).not_to have_selector '#monograph_visibility_lease'

      # Basic Metadata
      fill_in 'monograph[title]', with: '#hashtag Test Monograph Title with _MD Italics_ and <em>HTML Italics</em>'
      select press.name, from: I18n.t('press')
      fill_in 'Description', with: 'Blahdy blah description works'
      expect(page).to have_css('input.monograph_subject', count: 1)
      fill_in 'Subject', with: 'red stuff'
      expect(page).to have_css('input.monograph_language', count: 1)
      fill_in 'Language', with: 'English'
      fill_in 'Series', with: 'The Cereal Series'
      fill_in 'Section Titles', with: 'Intro\nChapter 1\nChapter 2'
      fill_in 'Buy Book URL(s)', with: 'http://www.example.com/buy'
      select 'Creative Commons Public Domain Mark 1.0', from: 'License'
      fill_in 'Copyright Holder', with: 'Blahdy Blah Copyright Holder'
      check 'Open Access?'
      fill_in 'Funder', with: 'Richie Rich'
      fill_in 'Funder Display', with: 'Made possible by Rich Richie'
      fill_in 'Holding Contact', with: 'http://www.blahpresscompany.com/'

      # Authorship Metadata
      # # 'Authors' is ambiguous
      fill_in 'monograph[creator]', with: "Johns, Jimmy\nWay, Sub (editor)"
      fill_in 'Contributor(s)', with: 'Shoppe, Sandwich (another unused role)'

      # Citation Metadata
      # publisher
      fill_in I18n.t(:publisher), with: 'Blah Press, Co.'
      # date_created
      fill_in 'Publication Year', with: '2001'
      # location
      fill_in 'Publication Location', with: 'Ann Arbor, MI.'
      # ISBNs
      expect(page).to have_css('input.monograph_isbn', count: 1)
      fill_in 'ISBN(s)', with: '123-456-7890'

      # Citable Links
      fill_in 'DOI', with: '<doi>'
      fill_in 'Handle', with: '<hdl>'
      fill_in 'Identifier', with: '<identifier>'

      click_button 'Save'

      # Monograph catalog page
      expect(page.title).to eq '#hashtag Test Monograph Title with MD Italics and HTML Italics'
      expect(page).to have_content '#hashtag Test Monograph Title with MD Italics and HTML Italics'
      # get text inside <em> tags
      italicized_text = page.first('.col-sm-8.col-sm-push-4.monograph-metadata h1 em').text
      expect(italicized_text).to eq 'MD Italics'
      expect(page).to have_content press.name
      expect(page).to have_content 'Blahdy blah description works'
      expect(page).to have_content 'Jimmy Johns, Sub Way and Sandwich Shoppe'
      expect(page).to have_field('Citable Link', with: HandleNet::DOI_ORG_PREFIX + '<doi>')
      expect(page).to have_content '123-456-7890'
      expect(page).to have_content 'Your files are being processed by Fulcrum in the background.'
      expect(page).not_to have_content 'Richie Rich' # funder
      expect(page).to have_content 'Made possible by Rich Richie' # funder_display

      # CC license icon/link
      expect(page).to have_css("img[src*='https://i.creativecommons.org/p/mark/1.0/80x15.png']", count: 1)
      expect(page).to have_link(nil, href: 'https://creativecommons.org/publicdomain/mark/1.0/')
      expect(page.find(:css, 'a[href="https://creativecommons.org/publicdomain/mark/1.0/"]')[:target]).to eq '_blank'

      # check breadcrumbs
      linked_crumbs = page.all('ol.breadcrumb li a')
      expect(linked_crumbs.count).to eq 1
      expect(linked_crumbs[0]).to have_content 'Home'
      unlinked_crumb = page.all('ol.breadcrumb li.active')
      expect(unlinked_crumb.count).to eq 1
      expect(unlinked_crumb.first).to have_content '#hashtag Test Monograph Title with MD Italics and HTML Italics'
      expect(unlinked_crumb.first).to have_css('em', text: 'MD Italics')
      expect(unlinked_crumb.first).to have_css('em', text: 'HTML Italics')

      click_link 'Edit'

      # back on Monograph form
      # add citation_display to test authorship override
      fill_in 'Authorship Display (free-form text)', with: 'Fancy Authorship Name Stuff That Takes Precedence'
      expect(page).to have_css('input.monograph_subject', count: 2)
      page.all(:fillable_field, 'monograph[subject][]').last.set('green stuff')
      expect(page).to have_css('input.monograph_language', count: 2)
      page.all(:fillable_field, 'monograph[language][]').last.set('German')
      expect(page).to have_css('input.monograph_series', count: 2)
      page.all(:fillable_field, 'monograph[series][]').last.set('The Second Series')
      expect(page).to have_css('input.monograph_isbn', count: 2)
      page.all(:fillable_field, 'monograph[isbn][]').last.set('123-456-7891')

      click_button 'Save'

      # back on Monograph catalog page
      # check authorship override
      expect(page).to have_content "Fancy Authorship Name Stuff That Takes Precedence"
      expect(page).not_to have_content "Jimmy Johns, Sub Way and Shoppe Sandwich"
      # series
      expect(page).to have_content 'The Cereal Series'
      expect(page).to have_content 'The Second Series'
      # copyright stuff
      expect(page).to have_content 'Blahdy Blah Copyright Holder'
      expect(page).to have_link("Blahdy Blah Copyright Holder", href: "http://www.blahpresscompany.com/")
      # Subject
      expect(page).to have_content 'red stuff'
      # ISBN
      expect(page).to have_content '123-456-7890'
      expect(page).to have_content '123-456-7891'

      click_link 'Manage Files'

      # On Monograph show page
      expect(page.title).to eq '#hashtag Test Monograph Title with MD Italics and HTML Italics'
      # Basic Metadata
      # title
      expect(page).to have_content '#hashtag Test Monograph Title with MD Italics and HTML Italics'
      # get text inside <em> tags
      italicized_text = page.first('.col-xs-12 header h1 em').text
      expect(italicized_text).to eq 'MD Italics'
      italicized_text = page.all('.col-xs-12 header h1 em').last.text
      expect(italicized_text).to eq 'HTML Italics'
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
      # license
      expect(page).to have_link("Creative Commons Public Domain Mark 1.0", href: "https://creativecommons.org/publicdomain/mark/1.0/")
      # copyright_holder
      expect(page).to have_content 'Blahdy Blah Copyright Holder'
      # holding_contact
      expect(page).to have_content 'http://www.blahpresscompany.com/'

      # open access
      expect(page).to have_css('li.attribute.open_access', text: 'yes', count: 1)
      # funder
      expect(page).to have_content 'Richie Rich'
      # funder display
      expect(page).to have_content 'Made possible by Rich Richie'


      # Citation Metadata
      # publisher
      expect(page).to have_content 'Blah Press, Co.'
      # date_created
      expect(page).to have_content '2001'
      expect(page).to have_content 'Ann Arbor, MI.'

      # ISBN
      expect(page).to have_content '123-456-7890'
      expect(page).to have_content '123-456-7891'

      # DOI
      expect(page).to have_content '<doi>'
      # Handle
      expect(page).to have_content '<hdl>'
      # Identifier
      expect(page).to have_content '<identifier>'

      # MLA citation
      expect(page).to have_content 'Johns, Jimmy, and Sub Way. #hashtag Test Monograph Title with MD Italics and HTML Italics. E-book, Ann Arbor, MI.'
      # APA citation
      expect(page).to have_content 'Johns, J., & Way, S. (2001). #hashtag Test Monograph Title with MD Italics and HTML Italics. https://doi.org/'
      # Chicago citation
      expect(page).to have_content 'Johns, Jimmy, and Sub Way. #hashtag Test Monograph Title with MD Italics and HTML Italics. Ann Arbor, MI.: Blah Press, Co., 2001'
    end
  end
end
