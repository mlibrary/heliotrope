# frozen_string_literal: true

require 'rails_helper'

describe 'FileSet Search' do
  let(:user) { create(:platform_admin) }
  let(:cover) { create(:file_set) }
  let(:file) { File.open(fixture_path + '/csv/shipwreck.jpg') }
  let(:file_set) {
    create(:public_file_set, user: user,
                             title: ["Blue"],
                             caption: ["Mr. Worf, It's better than music. It's jazz."])
  }
  let!(:monograph) do
    m = build(:monograph, title: ['Yellow'],
                          representative_id: cover.id)
    Hydra::Works::AddFileToFileSet.call(file_set, file, :original_file)
    m.ordered_members = [cover, file_set]
    m.save!
    m
  end

  let(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  before do
    cosign_login_as user
    stub_out_redis
    # Without this the file_set's solr_doc won't know it's monograph_id
    # which means you can't do things like @presenter.monograph.subdomain in the views
    file_set.update_index
  end

  it 'searches the monograph catalog page, not the catalog page' do
    visit hyrax_file_set_path(file_set)
    expect(page).to have_selector("form[action='/concern/monographs/#{monograph.id}?locale=en']")

    fill_in 'catalog_search', with: 'jazz'
    click_button 'keyword-search-submit'

    expect(page).to have_content 'Mr. Worf'

    # Selectors needed for assets/javascripts/ga_event_tracking.js
    # If these change, fix here then update ga_event_tracking.js
    expect(page).to have_selector('#keyword-search-submit')
    expect(page).to have_selector('#catalog_search')
  end
end
