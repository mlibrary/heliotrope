# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BAR full-text search', type: :system do
  let(:press) { create(:press, subdomain: 'barpublishing', default_list_view: false) }
  let(:monograph) { create(:public_monograph, press: press.subdomain, title: ['A book of passages'], identifier: ['bar_number:B375']) }
  let(:file_set) { create(:public_file_set, content: File.open(File.join(fixture_path, 'lorum_ipsum_toc.pdf'))) }

  before do
    stub_out_redis
    allow(Flipflop).to receive(:search_snippets?).and_return(true)
    monograph.ordered_members << file_set
    monograph.save!
    file_set.save!
    create(:featured_representative, work_id: monograph.id, file_set_id: file_set.id, kind: 'pdf_ebook')
    UnpackJob.perform_now(file_set.id, 'pdf_ebook')
    ActiveFedora::SolrService.commit
  end

  it 'keeps gallery browsing but shows text searches as a list with three non-linked samples' do
    visit press_catalog_path(press, view: 'gallery')
    expect(page).to have_css('#documents.documents-gallery')
    expect(page).to have_link('List')

    visit press_catalog_path(press, q: 'ipsum', view: 'gallery')
    expect(page).to have_css('#documents.documents-list')
    expect(page).not_to have_css('.view-type-group')
    within('.caption') do
      expect(page).to have_content('BAR Number: B375')
      expect(page).to have_css('.book-search-samples li', count: 3)
      expect(page).to have_css('.book-search-excerpt mark', text: /ipsum/i)
      expect(page).not_to have_css('.book-search-samples a')
      expect(page).to have_link('Search inside the book', href: epub_path(file_set.id, q: 'ipsum'))
    end

    visit press_catalog_path(press, user_access: 'true')
    expect(page).to have_css('#documents.documents-gallery')
    expect(page).to have_link('List')
  end

  it 'shows previews and a lock instead of a reader link for readers without access' do
    restrict_monograph!(monograph.id)
    visit press_catalog_path(press, q: 'ipsum')

    expect(page).to have_css('.book-search-samples li', count: 3)
    expect(page).to have_content('Full-book access required to search inside.')
    expect(page).to have_css('.book-search-restricted .fa-lock')
    expect(page).not_to have_link('Search inside the book')
  end
end
