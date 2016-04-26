require 'rails_helper'

feature 'Create a file set' do
  context 'a logged in user' do
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
      # Now attach a file to the Monograph by creating a FileSet
      click_link 'Attach a File'
      fill_in 'Title', with: 'Test file set'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      fill_in 'Resource Type', with: 'image'
      fill_in 'Caption', with: 'This is a caption for the image'
      fill_in 'Alternative Text', with: 'This is some alt text for the image'
      fill_in 'Copyright Holder', with: 'University of Michigan'
      fill_in 'Description', with: 'Veggies es bonus vobis, proinde vos postulo essum magis kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      fill_in 'Content Type', with: 'screenshot'
      fill_in 'Creator', with: 'Test Creator'
      fill_in 'Contributor', with: 'Test Contributor'
      fill_in 'Date created', with: '2016'
      fill_in 'Keywords', with: 'keyword 1'
      fill_in 'Language', with: 'English'
      fill_in 'Identifier', with: 'http://hdl.handle.net/1111'
      fill_in 'Relation', with: 'Introduction'
      click_button 'Attach to Monograph'
      # On Monograph Page
      expect(page).to have_css('tr.file_set td.attribute')
      click_link 'miranda.jpg'
      # On FileSet Page
      expect(page).to have_content 'Test file set'
      expect(page).to have_content 'image'
      expect(page).to have_content 'This is a caption for the image'
      expect(page).to have_content 'University of Michigan'
      expect(page).to have_content 'Veggies es bonus vobis, proinde vos postulo essum magis kohlrabi welsh onion daikon amaranth tatsoi tomatillo melon azuki bean garlic.'
      expect(page).to have_content 'screenshot'
      # TODO: Fix this
      # expect(page).to have_content 'Test Creator'
      expect(page).to have_content 'Test Contributor'
      expect(page).to have_content '2016'
      expect(page).to have_content 'keyword 1'
      expect(page).to have_content 'English'
      expect(page).to have_content 'Introduction'
    end
  end
end
