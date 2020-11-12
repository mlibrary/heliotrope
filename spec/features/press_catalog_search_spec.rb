# frozen_string_literal: true

require 'rails_helper'

describe 'Press Catalog' do
  before { Press.destroy_all }

  let(:umich) { create(:press, subdomain: 'umich') }
  let!(:red) {
    create(:public_monograph,
           title: ['The Red Book'],
           creator: ["Nyland, Jimbob"],
           press: umich.subdomain)
  }
  let!(:green) {
    create(:public_monograph,
           title: ['The Green Book'],
           creator: ["Doe, Jane\r\nSmith, John (editor)"],
           press: umich.subdomain)
  }
  let!(:blue) {
    create(:public_monograph,
           title: ['The Blue Book'],
           creator: ["McGinty, Timmy"],
           press: umich.subdomain)
  }

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
end
