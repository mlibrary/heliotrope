require 'rails_helper'

feature 'Create a file set' do
  context 'as a logged in user' do
    let(:user) { create(:platform_admin) }
    let!(:press) { create(:press) }

    before do
      login_as user
      stub_out_redis
    end

    scenario do
      # Start by creating a Monograph
      visit new_curation_concerns_monograph_path
      fill_in 'Title', with: 'Test monograph'
      select press.name, from: 'Publisher'
      fill_in 'Author (last name)', with: 'Johns'
      fill_in 'Author (first name)', with: 'Jimmy'
      fill_in 'Additional Authors', with: 'Sub Way'
      fill_in 'Date Published', with: 'Oct 20th'
      click_button 'Create Monograph'
      # On Monograph Page
      # Monograph page has authors
      expect(page).to have_content 'Jimmy Johns and Sub Way'

      # Create a Section
      visit new_curation_concerns_section_path
      fill_in 'Title', with: 'Test section with _Italicized Title_ therein'
      select 'Test monograph', from: "section_monograph_id"
      click_button 'Create Section'

      # Now attach a file to the Section. First create a FileSet
      click_link 'Attach a File'
      fill_in 'Title', with: 'Test file set'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      fill_in 'Resource Type', with: 'image'
      fill_in 'Caption', with: 'This is a caption for the image'
      fill_in 'Alternative Text', with: 'This is some alt text for the image'
      fill_in 'Copyright Holder', with: 'University of Michigan'
      fill_in 'Copyright Status', with: 'in-copyright'
      fill_in 'Rights Granted', with: 'look but don\'t download!'
      fill_in 'Rights Granted - Creative Commons', with: 'Creative Commons Attribution license, 3.0 Unported'
      fill_in 'Exclusive to Platform?', with: 'yes1'
      fill_in 'Allow Display After Expiration?', with: 'no1'
      fill_in 'Allow Download After Expiration?', with: 'no2'
      fill_in 'Description', with: 'Veggies es bonus vobis, [external link](www.external-link.com) proinde vos postulo essum magis [internal link](www.fulcrum.org) kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      fill_in 'Content Type', with: 'screenshot'
      fill_in 'Primary Creator (family name)', with: 'FamilyName'
      fill_in 'Primary Creator (given name)', with: 'GivenName'
      fill_in 'Primary Creator Role', with: 'director'
      fill_in 'Contributor', with: 'Test Contributor'
      fill_in 'Date Created', with: '2016'
      fill_in 'Sort Date', with: '2000-01-01'
      fill_in 'Permissions Expiration Date', with: '2026-01-01'
      fill_in 'Display Date', with: 'circa sometime for the (premiere, Berlin, LOLZ!)'
      fill_in 'Keywords', with: 'keyword 1'
      fill_in 'Language', with: 'English'
      fill_in 'Transcript', with: 'This is what is transcribed for you to read'
      fill_in 'Translation(s)', with: 'Here is what that&nbsp;means'
      fill_in 'Relation', with: 'Introduction'
      fill_in 'Externally-Hosted Resource?', with: 'no3'
      fill_in 'Book Needs Handles?', with: 'yes'
      fill_in 'External URL/DOI', with: 'Handle'
      fill_in 'Handle', with: "this-is-a-handle"
      fill_in 'Allow Download?', with: 'no4'
      fill_in 'Allow Hi-Res?', with: 'yes2'
      fill_in 'Credit Line', with: 'A Nice Museum'
      fill_in 'Holding Contact', with: 'Unauthorized use prohibited. A Nice Museum.'
      fill_in 'Use Crossref XML?', with: 'yes3'

      # Attach it to the Section
      click_button 'Attach to Section'
      click_link 'miranda.jpg'
      # On FileSet Page
      # FileSet page also has authors
      expect(page).to have_content 'Jimmy Johns and Sub Way'
      expect(page).to have_content 'Test file set'
      # expect(page).to have_content 'image'
      expect(page).to have_content 'This is a caption for the image'
      expect(page).to have_content 'University of Michigan'
      expect(page).to have_content 'Veggies es bonus vobis, external link proinde vos postulo essum magis internal link kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      expect(page).to have_content 'screenshot'
      expect(page).to have_content 'FamilyName, GivenName'
      expect(page).to have_content 'Test Contributor'
      expect(page).to have_content 'circa sometime for the (premiere, Berlin, LOLZ!)'
      # expect(page).to have_content '2000-01-01'
      # expect(page).to have_content '2026-01-01'
      expect(page).to have_content 'keyword 1'
      expect(page).to have_content 'English'
      # expect(page).to have_content 'Introduction'
      # expect(page).to have_content 'yes1'
      expect(page).to have_content 'This is what is transcribed for you to read'
      expect(page).to have_content 'Here is what that means'
      expect(page).to have_content 'A Nice Museum'
      expect(page).to have_content 'Unauthorized use prohibited. A Nice Museum.'
      expect(page.has_field?('Citable Link', with: 'http://hdl.handle.net/2027/fulcrum.this-is-a-handle')).to be true
      # expect(page).to have_content 'yes1'
      # expect(page).to have_content 'yes2'
      # expect(page).to have_content 'yes3'
      # expect(page).to have_content 'no1'
      # expect(page).to have_content 'no2'
      # expect(page).to have_content 'no3'
      # expect(page).to have_content 'no4'

      # check section title is present and renders italics/emphasis
      section_title = page.first('.list-unstyled .section_title a').text
      expect(section_title).to eq 'Test section with Italicized Title therein'
      italicized_text = page.first('.list-unstyled .section_title a em').text
      expect(italicized_text).to eq 'Italicized Title'

      # check metadata is linking as intended
      # facets
      expect(page).to have_link("keyword 1", href: "/concern/monographs/" + Monograph.first.id + "?f%5Bkeywords_sim%5D%5B%5D=keyword+1")
      expect(page).to have_link("English", href: "/concern/monographs/" + Monograph.first.id + "?f%5Blanguage_sim%5D%5B%5D=English")
      expect(page).to have_link("Test section with Italicized Title therein", href: "/concern/monographs/" + Monograph.first.id + "?f%5Bsection_title_sim%5D%5B%5D=Test+section+with+_Italicized+Title_+therein")
      expect(page).to have_link("FamilyName, GivenName", href: "/concern/monographs/" + Monograph.first.id + "?f%5Bcreator_full_name_sim%5D%5B%5D=FamilyName%2C+GivenName")
      expect(page).to have_link("Test Contributor", href: "/concern/monographs/" + Monograph.first.id + "?f%5Bcontributor_sim%5D%5B%5D=Test+Contributor")
      # search fields
      expect(page).to have_link("director", href: "/concern/monographs/" + Monograph.first.id + "?f%5Bprimary_creator_role_tesim%5D%5B%5D=director")
      expect(page).to have_link("screenshot", href: "/concern/monographs/" + Monograph.first.id + "?f%5Bcontent_type_tesim%5D%5B%5D=screenshot")

      # check external autolink are opening in a new tab and internal are not
      expect(find_link('external link')[:target]).to eq '_blank'
      expect(find_link('internal link')[:target]).to be nil
    end
  end
end
