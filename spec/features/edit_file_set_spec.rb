# frozen_string_literal: true

require 'rails_helper'

describe 'Edit a file set' do
  context 'as a logged in user' do
    let(:user) { create(:platform_admin) }

    let(:cover) { create(:public_file_set, user: user) }
    let(:monograph) do
      m = build(:monograph, title: ['Test monograph'],
                            representative_id: cover.id,
                            creator: ["Johns, Jimmy\nCreator, Wingperson M."],
                            contributor: ["Way, Sub\nContributor, Wingperson M."],
                            date_published: ['Oct 20th'],
                            section_titles: "C 1\nC 2\nTest section with _Italicized Title_ therein\nC 3\nC 4")
      m.ordered_members << cover
      m.save!
      m
    end

    let(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
    end

    let(:file) { File.open(fixture_path + '/csv/shipwreck.jpg') }
    let(:file_set_title) { '#hashtag Test FileSet Title with _MD Italics_ and <em>HTML Italics</em>' }
    let(:file_set_display_title) { '#hashtag Test FileSet Title with <em>MD Italics</em> and <em>HTML Italics</em>' }
    let(:file_set_page_title) { '#hashtag Test FileSet Title with MD Italics and HTML Italics' }

    let(:file_set) { create(:public_file_set, user: user, title: [file_set_title]) }

    let(:file_set_share_link) { "https://hdl.handle.net/2027/fulcrum.#{file_set.id}" }
    let(:url_escaped_title) { '%23hashtag+Test+FileSet+Title+with+MD+Italics+and+HTML+Italics' }

    before do
      login_as user
      stub_out_redis
      Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
      monograph.ordered_members << file_set
      monograph.save!
    end

    it do # rubocop:disable RSpec/ExampleLength
      visit edit_hyrax_file_set_path(file_set)

      # HELIO-3094
      expect(page).not_to have_selector '#file_set_visibility_authenticated' # institutional access
      expect(page).not_to have_selector '#file_set_visibility_embargo'
      expect(page).not_to have_selector '#file_set_visibility_lease'

      fill_in 'Resource Type', with: 'image'
      fill_in 'Caption', with: 'This is a caption for the image'
      fill_in 'Alternative Text', with: 'This is some alt text for the image'
      fill_in 'Copyright Holder', with: 'University of Michigan'
      fill_in 'Copyright Status', with: 'in-copyright'
      fill_in 'Rights Granted', with: 'look but don\'t download!'
      select 'Creative Commons Public Domain Mark 1.0', from: 'License'
      fill_in 'Exclusive to Platform?', with: 'yes1'
      fill_in 'Allow Display After Expiration?', with: 'no1'
      fill_in 'Allow Download After Expiration?', with: 'no2'
      fill_in 'Abstract or Summary', with: 'Veggies es bonus vobis, [external link](www.external-link.com) proinde vos postulo essum magis [internal link](www.fulcrum.org) kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      fill_in 'Content Type', with: 'screenshot'
      fill_in 'Creator', with: "FamilyName, GivenName (On Screen Talent)\nCreator, Wingperson F."
      fill_in 'Contributor', with: "Contributor, Mr A. (photographer)\nContributor, Wingperson F."
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

      fill_in 'External Resource URL', with: 'URL'
      fill_in 'Allow Download?', with: 'no4'
      fill_in 'Allow Hi-Res?', with: 'yes2'
      fill_in 'Credit Line', with: 'A Nice Museum'
      fill_in 'Holding Contact', with: 'Unauthorized use prohibited. A Nice Museum.'

      click_button 'Update Attached File'

      # Add another section title
      visit edit_hyrax_file_set_path(file_set)
      expect(page).to have_css('input.file_set_section_title', count: 2)
      page.all(:fillable_field, 'file_set[section_title][]').last.set('C 1')
      click_button 'Update Attached File'

      # Go to Monograph catalog page
      click_link 'Back to Monograph'
      expect(page).to have_current_path(hyrax_monograph_path(monograph, locale: 'en'))
      # Order in FileSet's section_title has been taken from Monograph's section_titles
      expect(page).to have_content 'From C 1 and Test section with Italicized Title therein'

      # check styled title is visible
      title_link = find("h4 a[href='/concern/file_sets/#{file_set.id}?locale=en']")
      expect(title_link).to have_content '#hashtag Test FileSet Title with MD Italics and HTML Italics'
      # check that the sentence includes the emphasised text
      expect(title_link).to have_css('em', text: 'MD Italics')
      expect(title_link).to have_css('em', text: 'HTML Italics')

      title_link.click

      expect(page).to have_current_path(hyrax_file_set_path(file_set, locale: 'en'))

      # On FileSet Page
      expect(page.title).to eq file_set_page_title
      heading_title = find('h1#asset-title')
      expect(heading_title).to have_content '#hashtag Test FileSet Title with MD Italics and HTML Italics'
      expect(heading_title).to have_css('em', text: 'MD Italics')
      expect(heading_title).to have_css('em', text: 'HTML Italics')

      # check breadcrumbs
      linked_crumbs = page.all('ol.breadcrumb li a')
      expect(linked_crumbs.count).to eq 2
      expect(linked_crumbs[0]).to have_content 'Home'
      expect(linked_crumbs[1]).to have_content 'Test monograph'
      unlinked_crumb = page.all('ol.breadcrumb li.active')
      expect(unlinked_crumb.count).to eq 1
      expect(unlinked_crumb.first).to have_content '#hashtag Test FileSet Title with MD Italics and HTML Italics'
      expect(unlinked_crumb.first).to have_css('em', text: 'MD Italics')
      expect(unlinked_crumb.first).to have_css('em', text: 'HTML Italics')

      # check share links
      share_links = page.all('.btn-group.share ul li a')
      expect(share_links.count).to eq 5
      expect(share_links[0].text).to eq 'Twitter'
      expect(share_links[0]['href']).to eq("http://twitter.com/intent/tweet?text=#{url_escaped_title}&url=#{file_set_share_link}")
      expect(share_links[0]['target']).to eq('_blank')
      expect(share_links[1].text).to eq 'Facebook'
      expect(share_links[1]['href']).to eq("http://www.facebook.com/sharer.php?u=#{file_set_share_link}&t=#{url_escaped_title}")
      expect(share_links[1]['target']).to eq('_blank')
      expect(share_links[2].text).to eq 'Reddit'
      expect(share_links[2]['href']).to eq("http://www.reddit.com/submit?url=#{file_set_share_link}")
      expect(share_links[2]['target']).to eq('_blank')
      expect(share_links[3].text).to eq 'Mendeley'
      expect(share_links[3]['href']).to eq("http://www.mendeley.com/import/?url=#{file_set_share_link}")
      expect(share_links[3]['target']).to eq('_blank')
      expect(share_links[4].text).to eq 'Cite U Like'
      expect(share_links[4]['href']).to eq("http://www.citeulike.org/posturl?url=#{file_set_share_link}&title=#{url_escaped_title}")
      expect(share_links[4]['target']).to eq('_blank')

      # FileSet page also has authors
      expect(page).to have_content 'Jimmy Johns, Wingperson M. Creator, Sub Way and Wingperson M. Contributor'
      expect(page).to have_content 'This is a caption for the image'
      expect(page).to have_link('Creative Commons Public Domain Mark 1.0', href: 'https://creativecommons.org/publicdomain/mark/1.0/')
      expect(find_link('Creative Commons Public Domain Mark 1.0')[:target]).to eq '_blank'
      expect(page).to have_content 'University of Michigan'
      expect(page).to have_content 'Veggies es bonus vobis, external link proinde vos postulo essum magis internal link kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      expect(page).to have_content 'screenshot'
      expect(page).to have_content 'FamilyName, GivenName'
      expect(page).to have_content 'Creator, Wingperson F.'
      expect(page).to have_content 'Contributor, Mr A. (photographer)'
      expect(page).to have_content 'Contributor, Wingperson F.'
      expect(page).to have_content 'circa sometime for the (premiere, Berlin, LOLZ!)'

      expect(page).to have_content 'Conor O\'Neill\'s'
      expect(page).to have_content 'English'
      expect(page).to have_content 'This is what is transcribed for you to read'
      expect(page).to have_content 'Here is what that means'
      expect(page).to have_content 'A Nice Museum'
      expect(page).to have_content 'Unauthorized use prohibited. A Nice Museum.'
      expect(page.has_field?('Citable Link', with: HandleService.url(file_set.id))).to be true

      # order in FileSet's section_title has been taken from Monograph's section_titles
      assert_equal page.all('.list-unstyled .section_title a').map(&:text), ['C 1', 'Test section with Italicized Title therein']

      # check facets
      expect(page).to have_link("Conor O'Neill's", href: "/concern/monographs/" + monograph.id + "?f%5Bkeywords_sim%5D%5B%5D=Conor+O%27Neill%27s")
      expect(page).to have_link("English", href: "/concern/monographs/" + monograph.id + "?f%5Blanguage_sim%5D%5B%5D=English")
      expect(page).to have_link("Test section with Italicized Title therein", href: "/concern/monographs/" + monograph.id + "?f%5Bsection_title_sim%5D%5B%5D=Test+section+with+_Italicized+Title_+therein")
      expect(page).to have_link("FamilyName, GivenName", href: "/concern/monographs/" + monograph.id + "?f%5Bcreator_sim%5D%5B%5D=FamilyName%2C+GivenName+%28On+Screen+Talent%29")

      # The "on screen talent" role was downcased on indexing
      expect(page).to have_link("on screen talent", href: "/concern/monographs/" + monograph.id + "?f%5Bprimary_creator_role_sim%5D%5B%5D=on+screen+talent")
      expect(page).to have_link("Contributor, Mr A. (photographer)", href: "/concern/monographs/" + monograph.id + "?f%5Bcontributor_sim%5D%5B%5D=Contributor%2C+Mr+A.+%28photographer%29")
      expect(page).to have_link("screenshot", href: "/concern/monographs/" + monograph.id + "?f%5Bcontent_type_sim%5D%5B%5D=screenshot")

      # check external autolink are opening in a new tab and internal are not
      expect(find_link('external link')[:target]).to eq '_blank'
      expect(find_link('internal link')[:target]).to be nil

      # Selectors needed for assets/javascripts/application/ga_event_tracking.js
      # If these change, fix here then update ga_event_tracking.js
      expect(page).to have_selector('ul.nav.nav-tabs li a', count: 3)

      # check facet results - bug #772
      # multi-word primary creator role facet
      click_link 'on screen talent'

      # check styled title is visible
      title_link = find("h4 a[href='/concern/file_sets/#{file_set.id}?locale=en']")
      expect(title_link).to have_content '#hashtag Test FileSet Title with MD Italics and HTML Italics'
      # check that the link includes the emphasised text
      expect(title_link).to have_css('em', text: 'MD Italics')
      expect(title_link).to have_css('em', text: 'HTML Italics')

      title_link.click

      # double html encoding breaking facet with apostrophe
      click_link 'Conor O\'Neill\'s'

      # check styled title is visible
      title_link = find("h4 a[href='/concern/file_sets/#{file_set.id}?locale=en']")
      expect(title_link).to have_content '#hashtag Test FileSet Title with MD Italics and HTML Italics'
      # check that the link includes the emphasised text
      expect(title_link).to have_css('em', text: 'MD Italics')
      expect(title_link).to have_css('em', text: 'HTML Italics')
    end
  end
end
