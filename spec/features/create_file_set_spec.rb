# frozen_string_literal: true

require 'rails_helper'

feature 'Create a file set' do
  context 'as a logged in user' do
    let(:user) { create(:platform_admin) }

    let(:cover) { create(:public_file_set, user: user) }
    let(:fs_title) { 'Test file set' }
    let(:monograph_id) { monograph.id }
    let(:monograph) do
      m = build(:monograph, title: ['Test monograph'],
                            representative_id: cover.id,
                            creator_family_name: 'Johns',
                            creator_given_name: 'Jimmy',
                            contributor: ['Sub Way'],
                            date_published: ['Oct 20th'],
                            section_titles: "C 1\nC 2\nTest section with _Italicized Title_ therein\nC 3\nC 4")
      m.ordered_members << cover
      m.save!
      m
    end
    let(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
    end

    before do
      login_as user
      stub_out_redis
    end

    scenario do
      visit monograph_show_path(monograph)

      # Now attach a file to the Monograph. First create a FileSet
      click_link 'Attach a File'
      fill_in 'Title', with: fs_title
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
      fill_in 'Primary Creator Role', with: 'on screen talent'
      fill_in 'Contributor', with: 'Test Contributor'
      fill_in 'Date Created', with: '2016'
      fill_in 'Sort Date', with: '2000-01-01'
      fill_in 'Permissions Expiration Date', with: '2026-01-01'
      fill_in 'Display Date', with: 'circa sometime for the (premiere, Berlin, LOLZ!)'
      # add apostrophes to prevent regression of double-html-encoding bug (#772)
      fill_in 'Keywords', with: 'Conor O\'Neill\'s'
      fill_in 'Language', with: 'English'
      fill_in 'Transcript', with: 'This is what is transcribed for you to read'
      fill_in 'Translation(s)', with: 'Here is what that&nbsp;means'

      # section_title is a multi-value field but it's not possible to add another without js: true (Selenium)
      # adding one now, will revisit the page to add the second section_title
      expect(page).to have_css('input.file_set_section_title', count: 1)
      fill_in 'Related Section', with: 'Test section with _Italicized Title_ therein'

      fill_in 'Externally-Hosted Resource?', with: 'no3'
      fill_in 'Book Needs Handles?', with: 'yes'
      fill_in 'External URL/DOI', with: 'Handle'
      fill_in 'Handle', with: "this-is-a-handle"
      fill_in 'Allow Download?', with: 'no4'
      fill_in 'Allow Hi-Res?', with: 'yes2'
      fill_in 'Credit Line', with: 'A Nice Museum'
      fill_in 'Holding Contact', with: 'Unauthorized use prohibited. A Nice Museum.'
      fill_in 'Use Crossref XML?', with: 'yes3'

      # Save the form
      click_button 'Attach to Monograph'

      # going back in to add a second section_title (seems easier than enabling JS for this test etc)
      visit edit_curation_concerns_file_set_path(FileSet.where(title: fs_title).first.id)
      expect(page).to have_css('input.file_set_section_title', count: 2)
      page.all(:fillable_field, 'file_set[section_title][]').last.set('C 1')
      click_button 'Update Attached File'

      # Go to Monograph catalog page
      click_link 'Back to Monograph'
      expect(page).to have_current_path(curation_concerns_monograph_path(monograph))
      # order in FileSet's section_title has been taken from Monograph's section_titles
      expect(page).to have_content 'From C 1 and Test section with Italicized Title therein'

      click_link fs_title

      # On FileSet Page
      # FileSet page also has authors
      expect(page).to have_content 'Jimmy Johns and Sub Way'
      expect(page).to have_content 'Test file set'
      expect(page).to have_content 'This is a caption for the image'
      expect(page).to have_content 'University of Michigan'
      expect(page).to have_content 'Veggies es bonus vobis, external link proinde vos postulo essum magis internal link kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      expect(page).to have_content 'screenshot'
      expect(page).to have_content 'FamilyName, GivenName'
      expect(page).to have_content 'Test Contributor'
      expect(page).to have_content 'circa sometime for the (premiere, Berlin, LOLZ!)'
      expect(page).to have_content 'Conor O\'Neill\'s'
      expect(page).to have_content 'English'
      expect(page).to have_content 'This is what is transcribed for you to read'
      expect(page).to have_content 'Here is what that means'
      expect(page).to have_content 'A Nice Museum'
      expect(page).to have_content 'Unauthorized use prohibited. A Nice Museum.'
      expect(page.has_field?('Citable Link', with: 'http://hdl.handle.net/2027/fulcrum.this-is-a-handle')).to be true

      # order in FileSet's section_title has been taken from Monograph's section_titles
      assert_equal page.all('.list-unstyled .section_title a').collect(&:text), ['C 1', 'Test section with Italicized Title therein']

      italicized_text = page.first('.list-unstyled .section_title a em').text
      expect(italicized_text).to eq 'Italicized Title'

      # check facets
      expect(page).to have_link("Conor O'Neill's", href: "/concern/monographs/" + monograph_id + "?f%5Bkeywords_sim%5D%5B%5D=Conor+O%27Neill%27s")
      expect(page).to have_link("English", href: "/concern/monographs/" + monograph_id + "?f%5Blanguage_sim%5D%5B%5D=English")
      expect(page).to have_link("Test section with Italicized Title therein", href: "/concern/monographs/" + monograph_id + "?f%5Bsection_title_sim%5D%5B%5D=Test+section+with+_Italicized+Title_+therein")
      expect(page).to have_link("FamilyName, GivenName", href: "/concern/monographs/" + monograph_id + "?f%5Bcreator_full_name_sim%5D%5B%5D=FamilyName%2C+GivenName")
      expect(page).to have_link("Test Contributor", href: "/concern/monographs/" + monograph_id + "?f%5Bcontributor_sim%5D%5B%5D=Test+Contributor")
      expect(page).to have_link("on screen talent", href: "/concern/monographs/" + monograph_id + "?f%5Bprimary_creator_role_sim%5D%5B%5D=on+screen+talent")
      expect(page).to have_link("screenshot", href: "/concern/monographs/" + monograph_id + "?f%5Bcontent_type_sim%5D%5B%5D=screenshot")

      # check external autolink are opening in a new tab and internal are not
      expect(find_link('external link')[:target]).to eq '_blank'
      expect(find_link('internal link')[:target]).to be nil

      # Selectors needed for assets/javascripts/ga_event_tracking.js
      # If these change, fix here then update ga_event_tracking.js
      expect(page).to have_selector('ul.nav.nav-tabs li a', count: 4)

      # check facet results - bug #772
      # multi-word primary creator role facet
      click_link 'on screen talent'
      expect(page).to have_content 'Test file set'
      click_link 'Test file set'
      # double html encoding breaking facet with apostrophe
      click_link 'Conor O\'Neill\'s'
      expect(page).to have_content 'Test file set'
    end
  end
end
