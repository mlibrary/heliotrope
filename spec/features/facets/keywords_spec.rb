# frozen_string_literal: true

require 'rails_helper'

describe "Monograph Catalog Keyword Facets", type: :feature do
  before do
    stub_out_redis
    stub_out_irus
  end

  let(:facets) { "#facets" }
  let(:selected_facets) { "#appliedParams" }
  let(:cover) { create(:public_file_set) }

  context "keywords" do
    let(:monograph) do
      m = build(:public_monograph, title: ["Yellow"], representative_id: cover.id)
      m.ordered_members = [cover, file_set]
      m.save!
      m
    end
    let(:file_set) { create(:public_file_set, keywords: %w[cat dog elephant lizard monkey mouse tiger]) }

    it "shows keywords in the intended order" do
      visit monograph_catalog_path(id: monograph.id)

      expect(page).to have_selector 'ul.facet-values li:nth-child(1)', text: 'cat'
      expect(page).to have_selector 'ul.facet-values li:nth-child(2)', text: 'dog'
      expect(page).to have_selector 'ul.facet-values li:nth-child(3)', text: 'elephant'
      expect(page).to have_selector 'ul.facet-values li:nth-child(4)', text: 'lizard'
      expect(page).to have_selector 'ul.facet-values li:nth-child(5)', text: 'monkey'
      expect(page).to have_selector 'ul.facet-values li:nth-child(6)', text: 'more'

      # Initially no facets selected
      expect(page).not_to have_css(selected_facets)
      # Facets rendered with facet_helper#render_facet_value

      within facets do
        cat_link = page.find_link('cat')
        expect(cat_link).to have_content('cat')
        expect(CGI.unescape(cat_link[:href])).to have_content("f[keywords_sim][]=cat")
        expect(cat_link[:'data-ga-event-category']).to be nil
        expect(cat_link[:'data-ga-event-action']).to eq("facet_keyword")
        expect(cat_link[:'data-ga-event-label']).to eq('cat')
        expect(cat_link[:'data-ga-event-value']).to be nil
        cat_link.click
      end

      # Cat facet selected
      expect(page).to have_css(selected_facets)
      # Cat facet rendered with facet_helper#render_selected_facet_value

      within facets do
        cat_link = page.find_link('cat')
        expect(cat_link).to have_content('cat')
        expect(CGI.unescape(cat_link[:href])).not_to have_content("f[keywords_sim][]=cat")
        expect(cat_link[:'data-ga-event-category']).to be nil
        expect(cat_link[:'data-ga-event-action']).to be nil
        expect(cat_link[:'data-ga-event-label']).to be nil
        expect(cat_link[:'data-ga-event-value']).to be nil
      end
    end
  end
end
