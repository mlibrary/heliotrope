# frozen_string_literal: true

require 'solr_helper'

# rubocop:disable RSpec/DescribeClass

RSpec.describe 'solr core' do
  let(:client) { SimpleSolrClient::Client.new(8985) }
  let(:core) { client.core('hydra-test') }

  describe 'field types' do
    let(:field_types) { core.schema.field_types }

    let(:expected_field_type_names) { %w[alphaSort ancestor_path boolean date descendent_path double float int isbn location location_rpt long point rand string tdate tdouble text textSuggest text_en text_ws tfloat tint tlong] }

    it { expect(field_types.map(&:name)).to match_array(expected_field_type_names) }

    describe 'isbn' do
      let(:isbn) { core.schema.field_type('isbn') }
      let(:isbn_input) { ['978-0-252012345 (paper)', '978-0252023456 (hardcover)', '978-1-62820-123-9 (e-book)'] }
      let(:isbn_indexed) { ['9780252012345', '9780252023456', '9781628201239'] }

      it do
        expect(isbn.solr_class).to eq('solr.TextField')
        expect(isbn.position_increment_gap).to eq('100')
        isbn_input.each_with_index do |input, index|
          expect(isbn.index_tokens(input)).to eq([isbn_indexed[index]])
          expect(isbn.query_tokens(input)).to eq(isbn.index_tokens(input))
        end
      end
    end
  end

  describe 'fields' do
    let(:fields) { core.schema.fields }

    let(:expected_field_names) { %w[_version_ all_text_timv id isbn_numeric lat lng timestamp] }

    it { expect(fields.map(&:name)).to match_array(expected_field_names) }

    describe 'isbn_numeric' do
      let(:isbn_numeric) { core.schema.field('isbn_numeric') }

      it do
        expect(isbn_numeric.type).to eq(core.schema.field_type('isbn'))
        expect(isbn_numeric.matcher).to eq('isbn_numeric')
        expect(isbn_numeric.stored?).to be false
        expect(isbn_numeric.indexed?).to be true
        expect(isbn_numeric.multiValued?).to be true
      end
    end
  end
end

# rubocop:enable RSpec/DescribeClass
