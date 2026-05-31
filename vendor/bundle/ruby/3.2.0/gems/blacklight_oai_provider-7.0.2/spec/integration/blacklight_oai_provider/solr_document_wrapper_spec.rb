require 'spec_helper'

RSpec.describe BlacklightOaiProvider::SolrDocumentWrapper do
  subject(:wrapper) { described_class.new(controller, options) }

  let(:options) { {} }
  let(:controller_class) { CatalogController }
  let(:controller) { controller_class.new }

  before do
    allow(controller).to receive(:params).and_return({})
  end

  describe '#earliest' do
    it 'returns the earliest timestamp of all the records' do
      expect(wrapper.earliest).to eq Time.parse('2014-02-03 18:42:53.056000000 +0000').utc
    end
  end

  describe '#latest' do
    it 'returns the latest timestamp of all the records' do
      expect(wrapper.latest).to eq Time.parse('2015-02-03 18:42:53.056000000 +0000').utc
    end
  end

  describe '#find' do
    context 'when selector is :all' do
      it 'returns a limited list of all records' do
        expect(wrapper.find(:all)).to be_a OAI::Provider::PartialResult
        expect(wrapper.find(:all).records.size).to be 15
      end
    end

    context 'when selector is an individual record' do
      let(:search_builder_class) do
        Class.new(Blacklight::SearchBuilder) do
          include Blacklight::Solr::SearchBuilderBehavior
          self.default_processor_chain += [:only_visible]

          def only_visible(solr_parameters)
            solr_parameters[:fq] ||= []
            solr_parameters[:fq] << 'visibility_si:"open"'
          end
        end
      end
      let(:controller_class) do
        stub_const 'VisibilitySearchBuilder', search_builder_class
        Class.new(CatalogController) do
          blacklight_config.configure do |config|
            config.search_builder_class = VisibilitySearchBuilder
          end
        end
      end

      it 'returns nothing for a restricted work' do
        expect(wrapper.find('2007020969')).to be_nil
      end

      it 'returns a single record for a public work' do
        expect(wrapper.find('2005553155')).to be_a SolrDocument
      end
    end
  end
end
