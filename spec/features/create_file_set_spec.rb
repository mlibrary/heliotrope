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
      select press.name, from: 'Press'
      fill_in 'Date Published', with: 'Oct 20th'
      click_button 'Create Monograph'
      # Go to monograph show page (not monograph catalog page)
      click_link 'Manage Monograph and Files'
      # Now attach a file to the Monograph by creating a FileSet
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
      fill_in 'Description', with: 'Veggies es bonus vobis, proinde vos postulo essum magis kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      fill_in 'Content Type', with: 'screenshot'
      fill_in 'Primary Creator (family name)', with: 'FamilyName'
      fill_in 'Primary Creator (given name)', with: 'GivenName'
      fill_in 'Contributor', with: 'Test Contributor'
      fill_in 'Date Created', with: '2016'
      fill_in 'Sort Date', with: '2000-01-01'
      fill_in 'Permissions Expiration Date', with: '2026-01-01'
      fill_in 'Display Date', with: 'circa sometime for the (premiere, Berlin, LOLZ!)'
      fill_in 'Keywords', with: 'keyword 1'
      fill_in 'Language', with: 'English'
      fill_in 'Transcript', with: 'This is what is transcribed for you to read'
      fill_in 'Translation(s)', with: 'Here is what that means'
      fill_in 'Identifier', with: 'http://hdl.handle.net/1111'
      fill_in 'Relation', with: 'Introduction'
      fill_in 'External Resource', with: 'no3'
      fill_in 'Book Needs Handles?', with: 'Handle'
      fill_in 'Allow Download?', with: 'no4'
      fill_in 'Allow Hi-Res?', with: 'yes2'
      fill_in 'Credit Line', with: 'A Nice Museum'
      fill_in 'Holding Contact', with: 'Unauthorized use prohibited. A Nice Museum.'
      fill_in 'External URL/DOI', with: 'Handle'
      fill_in 'Use Crossref XML?', with: 'yes3'

      click_button 'Attach to Monograph'
      # On Monograph Page
      click_link 'Test file set'
      # On FileSet Page
      expect(page).to have_content 'Test file set'
      # expect(page).to have_content 'image'
      expect(page).to have_content 'This is a caption for the image'
      expect(page).to have_content 'University of Michigan'
      expect(page).to have_content 'Veggies es bonus vobis, proinde vos postulo essum magis kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
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
      # expect(page).to have_content 'Handle'
      # expect(page).to have_content 'yes1'
      # expect(page).to have_content 'yes2'
      # expect(page).to have_content 'yes3'
      # expect(page).to have_content 'no1'
      # expect(page).to have_content 'no2'
      # expect(page).to have_content 'no3'
      # expect(page).to have_content 'no4'
    end
  end
end
