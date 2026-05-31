# frozen_string_literal: true
RSpec.shared_examples 'a Valkyrie::Persistence::Solr::Indexer' do |*_flags|
  let(:created_at) { Time.now.utc }
  let(:attributes) do
    {
      created_at: created_at,
      internal_resource: 'Resource',
      title: ["Test", RDF::Literal.new("French", language: :fr)],
      author: ["Author"],
      creator: "Creator"
    }
  end
  let(:resource) do
    Valkyrie::Specs::Resource.new(
      id: "1",
      internal_resource: 'Resource',
      attributes: attributes
    )
  end
  let(:indexer) { described_class.new(resource: resource) }

  before do
    class Valkyrie::Specs::Resource < Valkyrie::Resource
      attribute :title, Valkyrie::Types::Set
      attribute :author, Valkyrie::Types::Set
      attribute :birthday, Valkyrie::Types::DateTime.optional
      attribute :creator, Valkyrie::Types::String
    end
  end

  after do
    Valkyrie::Specs.send(:remove_const, :Resource)
  end

  describe '#to_solr' do
    subject { indexer.to_solr }

    it { is_expected.to be_a Hash }
  end
end
