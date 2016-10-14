require 'rails_helper'

feature 'Create an external resource' do
  context 'as a logged in user' do
    let(:user) { create(:platform_admin) }
    let!(:press) { create(:press) }

    before do
      login_as user
      stub_out_redis
    end

    # folowing create_file_set_spec.rb for the most part to create...
    # a fileset linking to an external resource with only metadata...
    # listed as 'required' in our metadata template

    scenario do
      # Start by creating a Monograph
      visit new_curation_concerns_monograph_path
      fill_in 'Title', with: 'Test monograph'
      select press.name, from: 'Publisher'
      fill_in 'Date Published', with: 'Oct 20th'
      click_button 'Create Monograph'
      # Go to monograph show page (not monograph catalog page)
      click_link 'Manage Monograph and Files'
      # Now attach a file to the Monograph by creating a FileSet
      click_link 'Attach a File'
      fill_in 'Title', with: 'Test external resource'
      attach_file 'file_set_files', File.join(fixture_path, 'csv', 'miranda.jpg')
      fill_in 'Resource Type', with: 'image'
      fill_in 'Caption', with: 'This is a caption for the external resource'
      fill_in 'Alternative Text', with: 'This is some alt text for the external resource'
      fill_in 'Copyright Holder', with: 'University of Michigan'
      fill_in 'Copyright Status', with: 'in-copyright'
      fill_in 'Exclusive to Platform?', with: 'BP'
      fill_in 'Allow Download?', with: 'no'
      fill_in 'Allow Hi-Res?', with: 'yes'

      fill_in 'External Resource', with: 'yes'
      fill_in 'External URL/DOI', with: 'https://www.example.com/blah'

      click_button 'Attach to Monograph'
      # On Monograph Page
      # The file we just added won't show up on the monograph catalog page since it's
      # the representative fileset. Navigate to the FileSet page
      click_link 'Manage Monograph and Files'
      click_link 'miranda.jpg'
      # On FileSet Page
      expect(page).to have_content 'Test external resource'
      expect(page).to have_content 'This is a caption for the external resource'
      expect(page).to have_content 'University of Michigan'
      # Look for the text highlighting this is an external resource
      expect(page).to have_content 'This is an external resource hosted on another website.'
      expect(page).to have_link(nil, href: "https://www.example.com/blah")
    end
  end
end
