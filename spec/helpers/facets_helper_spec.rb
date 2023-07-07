# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FacetsHelper do
  describe '#facet_pagination_sort_index_label' do
    subject { helper.facet_pagination_sort_index_label(facet_field) }

    let(:facet_field) { object_double(Blacklight::Configuration::FacetField.new(field: 'field').normalize!, 'facet_field', key: key) }
    let(:key) { 'key' }

    it { is_expected.to eq(t('blacklight.search.facets.sort.index')) }

    context 'when year' do
      let(:key) { 'search_year_sim' }

      it { is_expected.to eq('By Year') }
    end
  end

  describe '#facet_pagination_sort_count_label' do
    subject { helper.facet_pagination_sort_count_label(facet_field) }

    let(:facet_field) { object_double(Blacklight::Configuration::FacetField.new(field: 'field').normalize!, 'facet_field', key: key) }
    let(:key) { 'key' }

    it { is_expected.to eq(t('blacklight.search.facets.sort.count')) }

    context 'when year' do
      let(:key) { 'search_year_sim' }

      it { is_expected.to eq('Number of Items Available') }
    end
  end
end
