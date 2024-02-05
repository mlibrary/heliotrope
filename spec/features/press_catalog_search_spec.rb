# frozen_string_literal: true

require 'rails_helper'

describe 'Press Catalog' do
  let(:umich) { create(:press, subdomain: 'umich') }
  let(:red) do
    ::SolrDocument.new(id: 'red',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['The Red Book'],
                       creator_tesim: ["Nyland, Jimbob"],
                       press_sim: umich.subdomain,
                       read_access_group_ssim: ["public"])
  end
  let(:green) do
    ::SolrDocument.new(id: 'green',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['The Green Book'],
                       creator_tesim: ["Doe, Jane\r\nSmith, John (editor)"],
                       press_sim: umich.subdomain,
                       read_access_group_ssim: ["public"])
  end
  let(:blue) do
    ::SolrDocument.new(id: 'blue',
                       has_model_ssim: ['Monograph'],
                       title_tesim: ['The Blue Book'],
                       creator_tesim: ["McGinty, Timmy"],
                       press_sim: umich.subdomain,
                       read_access_group_ssim: ["public"],
                       table_of_contents_tesim: ["Yankee", "Hotel", "Foxtrot"])
  end

  before do
    Press.destroy_all
    ActiveFedora::SolrService.add([red.to_h, green.to_h, blue.to_h])
    ActiveFedora::SolrService.commit
  end

  # https://tools.lib.umich.edu/jira/browse/HELIO-2081
  it 'searches for second citable author' do
    visit "/#{umich.subdomain}"
    expect(page).to_not have_content("Your search has returned")
    expect(page.title).to eq umich.name

    fill_in 'q', with: 'Smith'
    click_button 'Search'
    expect(page.title).to eq "#{umich.name} results - page 1 of 1"
    expect(page).to have_selector('#documents .document', count: 1)
    expect(page).to have_content("Your search has returned 1 book from #{umich.name}")
    expect(page).to     have_link green.title.first
    expect(page).not_to have_link red.title.first
    expect(page).not_to have_link blue.title.first
  end

  it "searches the table of contents" do
    visit "/#{umich.subdomain}"
    expect(page).to_not have_content("Your search has returned")
    expect(page.title).to eq umich.name

    fill_in 'q', with: 'Hotel'
    click_button 'Search'
    expect(page).not_to have_link green.title.first
    expect(page).not_to have_link red.title.first
    expect(page).to have_link blue.title.first
  end
end
