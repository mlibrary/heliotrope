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
                            date_published: ['Oct 20th'])
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

      # On Monograph catalog page
      expect(page).to have_current_path(curation_concerns_monograph_path(monograph))
      click_link fs_title

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
      expect(page).to have_content 'Conor O\'Neill\'s'
      expect(page).to have_content 'English'
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
