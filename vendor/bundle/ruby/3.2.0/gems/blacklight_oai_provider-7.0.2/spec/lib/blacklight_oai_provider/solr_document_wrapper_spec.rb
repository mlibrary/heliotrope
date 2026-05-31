require 'spec_helper'

RSpec.describe BlacklightOaiProvider::SolrDocumentWrapper do
  subject(:wrapper) { described_class.new(controller, options) }

  let(:options) { {} }
  let(:controller_class) { CatalogController }
  let(:controller) { instance_double(CatalogController) }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(controller).to receive_messages(params: {}, blacklight_config: blacklight_config)
  end

  describe '#initialize' do
    context 'with a set class provided' do
      before do
        stub_const 'CustomSet', Class.new(BlacklightOaiProvider::Set)
      end

      let(:options) { { set_model: CustomSet, set_fields: [{ solr_field: 'language_facet' }] } }

      it 'uses the Set class' do
        expect(wrapper.instance_eval { @set }).to be CustomSet
      end
    end
  end

  describe '#sets' do
    it 'returns nil to indicate sets are not supported' do
      expect(wrapper.sets).to be_nil
    end
  end

  shared_context "timestamp_searches" do
    let(:expected_timestamp) { '2014-02-03 18:42:53.056000000 +0000' }
    let(:repository) { instance_double(Blacklight::Solr::Repository) }
    let(:search_builder) { instance_double(Blacklight::SearchBuilder) }
    let(:search_service) { instance_double(Blacklight::SearchService) }
    let(:documents) { [SolrDocument.new('timestamp' => expected_timestamp)] }
    let(:response) { OpenStruct.new(documents: documents, total: documents.length) }

    before do
      allow(controller).to receive(:search_service).and_return(search_service)
      allow(search_service).to receive_messages(repository: repository, search_builder: search_builder)
      allow(repository).to receive(:search).with(search_builder).and_return(response)
    end
  end

  describe '#earliest' do
    include_context "timestamp_searches"

    before do
      allow(search_builder).to receive(:merge).with(hash_including(sort: "timestamp asc")).and_return(search_builder)
    end

    it 'returns the earliest timestamp of all the records' do
      expect(wrapper.earliest).to eq Time.parse(expected_timestamp).utc
    end

    context "no documents are returned" do
      let(:documents) { [] }

      it 'returns a default timestamp' do
        expect(Time.parse(wrapper.earliest).utc).to be_a Time
      end
    end
  end

  describe '#latest' do
    include_context "timestamp_searches"

    before do
      allow(search_builder).to receive(:merge).with(hash_including(sort: "timestamp desc")).and_return(search_builder)
    end

    it 'returns the latest timestamp of all the records' do
      expect(wrapper.latest).to eq Time.parse(expected_timestamp).utc
    end

    context "no documents are returned" do
      let(:documents) { [] }

      it 'returns a default timestamp' do
        expect(Time.parse(wrapper.latest).utc).to be_a Time
      end
    end
  end

  describe '#find' do
    include_context "timestamp_searches"

    subject(:result) { wrapper.find(selector) }

    context 'when selector is :all' do
      let(:selector) { :all }
      let(:query) { {} }
      let(:limit) { 1 }
      let(:options) { { limit: limit } }
      let(:response) { OpenStruct.new(documents: documents, total: limit + 1) }
      let(:next_response) { OpenStruct.new(documents: documents, total: documents.length) }

      before do
        allow(search_builder).to receive_messages(merge: search_builder, query: query)
        allow(repository).to receive(:search).with(query).and_return(response)
        allow(repository).to receive(:search).with(hash_including(start: 0)).and_return(next_response)
      end

      it 'returns a limited list of all records' do
        expect(result).to be_a OAI::Provider::PartialResult
        expect(result.records.size).to be limit
      end
    end

    context 'when selector is an id value' do
      let(:selector) { '2007020969' }
      let(:query) { {} }

      before do
        allow(search_builder).to receive(:query).and_return(query)
        allow(repository).to receive(:search).with(query).and_return(response)
        allow(search_builder).to receive(:where).with(id: selector).and_return(search_builder)
      end

      it 'searches by id' do
        expect(result).to be_a(SolrDocument)
        expect(search_builder).to have_received(:where).with(id: selector)
      end
    end
  end

  describe '#conditions' do
    include_context "timestamp_searches"

    subject(:result) { wrapper.conditions(constraints) }

    let(:search_builder_class) do
      Class.new(Blacklight::SearchBuilder) do
        include Blacklight::Solr::SearchBuilderBehavior
      end
    end
    let(:search_builder) { search_builder_class.new(controller) }

    context 'time options' do
      let(:constraints) { { from: Time.utc(2015, 1, 1), until: Time.utc(2015, 1, 2) } }

      it 'sets options when from' do
        constraints.delete(:until)
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01T00:00:00Z TO *]"],
          "sort" => "timestamp asc"
        )
      end

      it 'sets options when until' do
        constraints.delete(:from)
        expect(result).to include(
          "fq" => ["timestamp:[* TO 2015-01-02T00:00:00.999Z]"],
          "sort" => "timestamp asc"
        )
      end

      it 'sets options when range' do
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01T00:00:00Z TO 2015-01-02T00:00:00.999Z]"],
          "sort" => "timestamp asc"
        )
      end
    end

    context 'date options' do
      let(:constraints) { { from: Date.parse('2015-01-01'), until: Date.parse('2015-01-02') } }

      it 'sets options for high granularity' do
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01T00:00:00Z TO 2015-01-02T23:59:59.999Z]"],
          "sort" => "timestamp asc"
        )
      end
      # rubocop:disable RSpec/NestedGroups
      context 'low granularity' do
        let(:options) { { granularity: OAI::Const::Granularity::LOW } }

        it 'sets options' do
          expect(wrapper.granularity).to eql(OAI::Const::Granularity::LOW)
          expect(result).to include(
            "fq" => ["timestamp:[2015-01-01 TO 2015-01-02]"],
            "sort" => "timestamp asc"
          )
        end
        context 'same value for endpoints' do
          let(:constraints) { { from: Date.parse('2015-01-01'), until: Date.parse('2015-01-01') } }

          it 'sets options' do
            expect(wrapper.granularity).to eql(OAI::Const::Granularity::LOW)
            expect(result).to include(
              "fq" => ["timestamp:\"2015-01-01\""],
              "sort" => "timestamp asc"
            )
          end
        end
      end
      # rubocop:enable RSpec/NestedGroups
    end

    context 'string date options' do
      let(:constraints) { { from: '2015-01-01', until: '2015-01-02' } }

      it 'sets options when from' do
        constraints.delete(:until)
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01 TO *]"],
          "sort" => "timestamp asc"
        )
      end
      it 'sets options when until' do
        constraints.delete(:from)
        expect(result).to include(
          "fq" => ["timestamp:[* TO 2015-01-02]"],
          "sort" => "timestamp asc"
        )
      end
      it 'sets options when range' do
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01 TO 2015-01-02]"],
          "sort" => "timestamp asc"
        )
      end
    end

    context 'string time options' do
      let(:constraints) { { from: '2015-01-01T00:00:00.000Z', until: '2015-01-02T00:00:00.000Z' } }

      it 'sets options when from' do
        constraints.delete(:until)
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01T00:00:00.000Z TO *]"],
          "sort" => "timestamp asc"
        )
      end
      it 'sets options when until' do
        constraints.delete(:from)
        expect(result).to include(
          "fq" => ["timestamp:[* TO 2015-01-02T00:00:00.000Z]"],
          "sort" => "timestamp asc"
        )
      end
      it 'sets options when range' do
        expect(result).to include(
          "fq" => ["timestamp:[2015-01-01T00:00:00.000Z TO 2015-01-02T00:00:00.000Z]"],
          "sort" => "timestamp asc"
        )
      end
    end
  end
end
