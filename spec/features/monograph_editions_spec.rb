# frozen_string_literal: true

require 'rails_helper'

describe 'Press Catalog' do
  before do
    create(:press, subdomain: 'michigan')

    create(:public_monograph,
           id: '111111111',
           title: ['The First Edition Title'],
           press: 'michigan',
           date_created: ['2000'],
           edition_name: 'First Edition Name',
           next_edition: 'https://doi.org/10.3998/mpub.2222222',
           doi: '10.3998/mpub.1111111',
           isbn: ['978-0-472-55555-1'])

    create(:public_monograph,
           id: '222222222',
           title: ['The Second Edition Title'],
           press: 'michigan',
           date_created: ['2010'],
           edition_name: 'Second Edition Name',
           previous_edition: 'https://doi.org/10.3998/mpub.1111111',
           next_edition: 'https://doi.org/10.3998/mpub.3333333',
           doi: '10.3998/mpub.2222222',
           isbn: ['978-0-472-55555-2'])

    create(:public_monograph,
           id: '333333333',
           title: ['The Third Edition Title'],
           press: 'michigan',
           date_created: ['2020'],
           edition_name: 'Third Edition Name',
           previous_edition: 'https://doi.org/10.3998/mpub.2222222',
           doi: '10.3998/mpub.3333333',
           isbn: ['978-0-472-55555-3'])
  end

  it 'shows expected edition info on press page' do
    visit "/michigan"

    expect(page).to have_selector('#documents .document', count: 3)

    expect(page).to have_link 'The First Edition Title'
    expect(page).to have_text '2000, First Edition Name'

    expect(page).to have_link 'The Second Edition Title'
    expect(page).to have_text '2010, Second Edition Name'

    expect(page).to have_link 'The Third Edition Title'
    expect(page).to have_text '2020, Third Edition Name'
  end

  it 'shows expected edition info on each monograph page' do
    visit Rails.application.routes.url_helpers.hyrax_monograph_url('111111111')
    expect(page).to have_link('Read a newer version of The First Edition Title',
                              href: 'https://doi.org/10.3998/mpub.2222222')
    # monograph's own Altmetric data
    expect(page).to have_css('div[data-isbn="978-0-472-55555-1"]')
    expect(page).to have_css('span[data-doi="10.3998/mpub.1111111"]')
    # previous edition's Altmetric data (none)
    expect(page).to_not have_css('div.previous-edition-metrics')


    visit Rails.application.routes.url_helpers.hyrax_monograph_url('222222222')
    expect(page).to have_link('Looking for an older version of The Second Edition Title?',
                              href: 'https://doi.org/10.3998/mpub.1111111')
    expect(page).to have_link('Read a newer version of The Second Edition Title',
                              href: 'https://doi.org/10.3998/mpub.3333333')
    # monograph's own Altmetric data
    expect(page).to have_css('div[data-isbn="978-0-472-55555-2"]')
    expect(page).to have_css('span[data-doi="10.3998/mpub.2222222"]')
    # previous edition's Altmetric data
    expect(page).to have_css('div.previous-edition-metrics')
    expect(page).to have_text 'First Edition Name'
    expect(page).to have_css('div[data-isbn="978-0-472-55555-1"]')
    expect(page).to have_css('span[data-doi="10.3998/mpub.1111111"]')

    visit Rails.application.routes.url_helpers.hyrax_monograph_url('333333333')
    expect(page).to have_link('Looking for an older version of The Third Edition Title?',
                              href: 'https://doi.org/10.3998/mpub.2222222')
    # monograph's own Altmetric data
    expect(page).to have_css('div[data-isbn="978-0-472-55555-3"]')
    expect(page).to have_css('span[data-doi="10.3998/mpub.3333333"]')
    # previous edition's Altmetric data
    expect(page).to have_css('div.previous-edition-metrics')
    expect(page).to have_text 'Second Edition Name'
    expect(page).to have_css('div[data-isbn="978-0-472-55555-2"]')
    expect(page).to have_css('span[data-doi="10.3998/mpub.2222222"]')
  end
end
