require 'spec_helper'

RSpec.describe BlacklightOaiProvider::SolrSet do
  let(:controller) { CatalogController.new }
  let(:fields) do
    [{ label: 'language', solr_field: 'language_ssim' }]
  end

  before do
    described_class.controller = controller
    described_class.fields = fields
    allow(controller).to receive(:params).and_return({})
  end

  describe '.all' do
    subject(:all_sets) { described_class.all }

    it 'returns a Set object representing each set' do
      expect(all_sets.count).to be 12
      expect(all_sets.first).to be_a described_class
    end

    context 'with multiple fields' do
      let(:fields) do
        [
          { label: 'language', solr_field: 'language_ssim' },
          { solr_field: 'format' }
        ]
      end

      it 'returns Sets for values in each field' do
        expect(all_sets.count).to be 13
      end
    end

    context 'for a field with no values' do
      let(:fields) do
        [{ label: 'author', solr_field: 'author_ts' }]
      end

      it 'returns nil' do
        expect(all_sets).to be_nil
      end
    end

    context 'for a field with facet config limit' do
      let(:fields) do
        [{ label: 'lc_alpha', solr_field: 'lc_alpha_ssim' }]
      end

      before do
        CatalogController.configure_blacklight do |config|
          config.add_facet_field 'lc_alpha_ssim', label: 'lc_alpha', limit: 2
        end
      end

      it 'returns all sets' do
        expect(all_sets.count).to be 14
      end
    end
  end

  describe '.from_spec' do
    context 'with a valid spec' do
      let(:spec) { 'language:Hebrew' }

      it 'returns the filter query' do
        expect(described_class.from_spec(spec)).to eq 'language_ssim:"Hebrew"'
      end
    end

    context 'with an invalid field' do
      let(:spec) { 'foo:Hebrew' }

      it 'raises an argument exception' do
        expect { described_class.from_spec(spec) }.to raise_error(::OAI::ArgumentException)
      end
    end

    context 'with an invalid spec' do
      let(:spec) { 'invalid' }

      it 'raises an argument exception' do
        expect { described_class.from_spec(spec) }.to raise_error(::OAI::ArgumentException)
      end
    end
  end

  describe '#initialize' do
    let(:set) { described_class.new('language:Hebrew') }

    it 'creates a friendly set name if none is provided' do
      expect(set.name).to eq 'Language: Hebrew'
    end

    it 'gets solr field' do
      expect(set.solr_field).to eql 'language_ssim'
    end
  end
end
