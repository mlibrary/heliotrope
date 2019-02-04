# frozen_string_literal: true

require 'rails_helper'

describe 'Catalog search' do
  context 'a user who is not logged in' do
    let!(:private_monograph) { create(:private_monograph) }
    let!(:public_monograph) { create(:public_monograph) }

    it 'visits the catalog page' do
      skip "Quiet Blacklight DEPRECATION WARNINGS that are in Hyrax itself and will likely(?) by fixed in Hyrax 3.\nhttps://github.com/samvera/hyrax/commit/4a476aabf967e634ba54269794afb62982a129c0\nWe don't use the bare /catalog anyway so skipping the spec is fine for now."

      visit search_catalog_path

      # There should be this many search results total:
      expect(page).to have_selector('.catalog .document', count: 1)

      expect(page).to have_link public_monograph.title.first
      expect(page).not_to have_link private_monograph.title.first
    end
  end
end
