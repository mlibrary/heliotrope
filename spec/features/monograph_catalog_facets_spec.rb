# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Facets" do
  before do
    stub_out_redis
  end

  let(:facets) { "#facets" }
  let(:selected_facets) { "#appliedParams" }
  let(:cover) { create(:public_file_set) }
  let!(:sipity_entity) do
    create(:sipity_entity, proxy_for_global_id: monograph.to_global_id.to_s)
  end

  context "all facets" do
    let(:monograph) { create(:public_monograph, title: ["Yellow"], representative_id: cover.id) }
    let(:file_set) {
      create(:public_file_set, resource_type: ['image'],
                               exclusive_to_platform: 'yes',
                               creator: ["McTesterson, Testy\nCoauthorson, Timmy"],
                               sort_date: '1974-01-01',
                               keywords: ['stuff', 'things'],
                               section_title: ['A Section'])
    }

    before do
      monograph.ordered_members = [cover, file_set]
      monograph.save!
    end

    it "shows the correct facets" do
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to have_selector('#facet-section_title_sim a.facet_select')
      expect(page).to have_selector('#facet-keywords_sim a.facet_select', count: 2)
      expect(page).to have_selector('#facet-keywords_sim a.facet_select', text: 'stuff')
      expect(page).to have_selector('#facet-keywords_sim a.facet_select', text: 'things')
      expect(page).to have_selector('#facet-creator_sim a.facet_select', count: 2)
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'McTesterson, Testy')
      expect(page).to have_selector('#facet-creator_sim a.facet_select', text: 'Coauthorson, Timmy')
      expect(page).to have_selector('#facet-resource_type_sim a.facet_select', text: 'image')
      expect(page).to have_selector('#facet-search_year_sim a.facet_select')
      expect(page).to have_selector('#facet-exclusive_to_platform_sim a.facet_select')
    end
  end
end
