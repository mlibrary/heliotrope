# frozen_string_literal: true

require 'rails_helper'

describe 'Monograph Catalog Visibility' do
  let(:monograph) do
    m = build(:public_monograph, representative_id: cover.id)
    m.ordered_members = [cover, fs1, fs2]
    m.save!
    m
  end

  let(:cover) { create(:public_file_set) }
  let(:fs1) { create(:file_set) }
  let(:fs2) { create(:file_set) }

  before do
    stub_out_redis
    stub_out_irus
  end

  context 'no published Resources' do
    it 'no results on Monograph catalog page' do
      visit monograph_catalog_path(monograph.id)

      expect(page).not_to have_css('.row.monograph-assets')
      expect(page).not_to have_css('#documents .documents-list')
    end
  end

  # see HELIO-4814
  context '1 published and 1 unpublished resource FileSets' do
    let(:fs1) { create(:public_file_set) }

    before { monograph.save }
    it 'only shows the published FileSet' do
      visit monograph_catalog_path(monograph.id)

      expect(page).to have_css('.row.monograph-assets')
      expect(page).to have_css('#documents.documents-list')
      expect(page).to have_css('.row.document.blacklight-fileset', count: 1)
    end
  end

  context '2 published resource FileSets' do
    let(:fs1) { create(:public_file_set) }
    let(:fs2) { create(:public_file_set) }

    before { monograph.save }
    it 'only shows the published FileSet' do
      visit monograph_catalog_path(monograph.id)

      expect(page).to have_css('.row.monograph-assets')
      expect(page).to have_css('#documents.documents-list')
      expect(page).to have_css('.row.document.blacklight-fileset', count: 2)
    end
  end
end
