# frozen_string_literal: true

require 'rails_helper'

describe 'Create an external resource' do
  context 'as a logged in user' do
    let(:user) { create(:platform_admin) }

    # We need to be able to accept "fileless" file_sets, which will
    # just be links to "external resources". Right now in Hyrax there's
    # no way to create a file_set w/o a file in the UI, so we need to
    # cheat a little. In the future we need to modify the UI so that it's
    # possible to create a file_set w/o a file.
    # TODO: enable the creation of "fileless" external resources through the UI (don't attach_file below)

    let(:cover) { create(:public_file_set, user: user) }
    let(:monograph) do
      m = build(:monograph, title: ['Test monograph'],
                            representative_id: cover.id,
                            creator: ['Johns, Jimmy'],
                            contributor: ['Sub Way'],
                            date_published: ['Oct 20th'])
      m.ordered_members << cover
      m.save!
      m
    end

    let(:sipity_entity) do
      create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
    end

    let(:file) { File.open(fixture_path + '/csv/shipwreck.jpg') }
    let(:file_set_title) { "Test External Resource" }
    let(:file_set) { create(:public_file_set, user: user, title: [file_set_title]) }

    before do
      login_as user
      stub_out_redis
      stub_out_irus
      Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
      monograph.ordered_members << file_set
      monograph.save!
      file_set.save!
    end

    it do
      visit edit_hyrax_file_set_path(file_set)

      fill_in 'Resource Type', with: 'image'
      fill_in 'Caption', with: 'This is a caption for the external resource'
      fill_in 'Alternative Text', with: 'This is some alt text for the external resource'
      fill_in 'Copyright Holder', with: 'University of Michigan'
      fill_in 'Copyright Status', with: 'in-copyright'
      fill_in 'Exclusive to Platform?', with: 'no'
      fill_in 'Allow Download?', with: 'no'
      fill_in 'Allow Hi-Res?', with: 'yes'
      fill_in 'External Resource URL', with: 'https://www.example.com/blah'

      click_button 'Update Attached File'

      # On Monograph Page
      # check the direct links to the external resource from both list and gallery views
      visit monograph_catalog_path(monograph)

      click_link 'Gallery'
      expect(find('#documents')['class']).to include('gallery')
      expect(page).to have_link('Open external resource at https://www.example.com', href: "https://www.example.com/blah")

      click_link 'List'
      expect(find('#documents')['class']).to include('documents-list')
      expect(page).to have_link('Open external resource at https://www.example.com', href: "https://www.example.com/blah")

      # On FileSet Page
      visit hyrax_file_set_path(file_set)

      expect(page).to have_content file_set_title
      expect(page).to have_content 'This is a caption for the external resource'
      expect(page).to have_content 'University of Michigan'
      # Look for the text highlighting this is an external resource
      expect(page).to have_content 'This is an external resource hosted at https://www.example.com. When selecting the button above you will be leaving this website.'
      expect(page).to have_link(nil, href: "https://www.example.com/blah")

      # no image present on an external resource's FileSet page
      expect(page).not_to have_css('div.image')
    end
  end
end
