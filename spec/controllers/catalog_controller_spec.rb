# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CatalogController, type: :controller do
  describe 'blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    it 'search_builder_class' do
      expect(blacklight_config.search_builder_class).to be ::SearchBuilder
    end

    describe 'default_solr_params' do
      subject(:default_solr_params) { blacklight_config.default_solr_params }

      # Fields to query
      it 'qf' do
        expected_tesim_fields = %w[title creator creator_full_name creator_display subject description keywords contributor caption transcript translation alt_text identifier]
        expected_fields = expected_tesim_fields.map { |field| described_class.solr_name(field, :stored_searchable) }
        expected_fields << 'isbn'
        expect(default_solr_params[:qf].split(' ')).to match_array(expected_fields)
      end

      # Select handler
      it 'qt' do
        expect(default_solr_params[:qt]).to eq('search')
      end

      # Rows per page
      it 'rows' do
        expect(default_solr_params[:rows]).to eq 10
      end
    end
  end

  describe 'controller' do
    it '#show_site_search?' do
      expect(controller.show_site_search?).to equal true
    end

    it 'render_bookmarks_control?' do
      expect(controller.render_bookmarks_control?).to equal false
    end
  end
end
