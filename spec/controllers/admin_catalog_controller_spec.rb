# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminCatalogController, type: :controller do
  describe 'blacklight_config' do
    subject(:blacklight_config) { described_class.blacklight_config }

    it 'builds without raising (no duplicate facet_field keys)' do
      expect { blacklight_config }.not_to raise_error
    end

    it 'uses the full-catalog search builder shared with CatalogController' do
      expect(blacklight_config.search_builder_class).to be ::CatalogSearchBuilder
    end

    describe 'facet_fields' do
      subject(:facet_keys) { blacklight_config.facet_fields.keys }

      it 'has no duplicate keys' do
        expect(facet_keys).to eq facet_keys.uniq
      end

      it 'includes the new admin-only Subdomain and Published? facets' do
        expect(facet_keys).to include('press_sim', 'visibility_ssi')
      end

      it 'includes facets carried over from PressCatalogController' do
        expect(facet_keys).to include('funder_sim', 'author_place_of_origin_sim', 'publisher_sim',
                                      'collection_sim', 'series_sim', 'press_name_sim',
                                      'product_names_sim', 'reader_ebook_format_sim')
      end

      it 'includes facets carried over from MonographCatalogController' do
        expect(facet_keys).to include('section_title_sim', 'keyword_sim', 'content_type_sim',
                                      'resource_type_sim', 'search_year_sim',
                                      'exclusive_to_platform_sim', 'contributor_sim',
                                      'primary_creator_role_sim')
      end

      it 'keeps single subject_sim/creator_sim entries' do
        expect(facet_keys.count('subject_sim')).to eq 1
        expect(facet_keys.count('creator_sim')).to eq 1
      end

      it 'does not inherit the public catalog-only facets (it is a sibling, not a subclass)' do
        expect(facet_keys).not_to include('human_readable_type_sim', 'tag_sim',
                                          'based_near_sim', 'press_name_ssim', 'generic_type_sim')
      end
    end
  end

  describe 'inheritance' do
    it 'is a sibling of CatalogController under ApplicationCatalogController' do
      expect(described_class.superclass).to be ApplicationCatalogController
      expect(described_class.ancestors).not_to include CatalogController
    end
  end
end
