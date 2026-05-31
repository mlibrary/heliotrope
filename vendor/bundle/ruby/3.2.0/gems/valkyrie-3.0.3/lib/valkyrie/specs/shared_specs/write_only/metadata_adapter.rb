# frozen_string_literal: true
RSpec.shared_examples 'a write-only Valkyrie::MetadataAdapter' do |passed_adapter|
  before do
    raise 'adapter must be set with `let(:adapter)`' unless
      defined? adapter
  end
  subject { passed_adapter || adapter }
  let(:persister) { adapter.persister }
  it { is_expected.to respond_to(:persister).with(0).arguments }
  it { is_expected.to respond_to(:id).with(0).arguments }

  describe "#id" do
    it "is a valid string representation of an MD5 hash" do
      expect(adapter.id).to be_a Valkyrie::ID
      expect(adapter.id.to_s.length).to eq 32
      expect(adapter.id.to_s).to match(/^[a-f,0-9]+$/)
    end
  end

  describe "#write_only?" do
    it "returns true" do
      expect(adapter).to be_write_only
    end
  end

  describe "persister" do
    before do
      class WriteOnlyCustomResource < Valkyrie::Resource
        include Valkyrie::Resource::AccessControls
        attribute :title
        attribute :author
        attribute :other_author
        attribute :member_ids
        attribute :nested_resource
        attribute :single_value, Valkyrie::Types::String.optional
        attribute :ordered_authors, Valkyrie::Types::Array.of(Valkyrie::Types::Anything).meta(ordered: true)
        attribute :ordered_nested, Valkyrie::Types::Array.of(WriteOnlyCustomResource).meta(ordered: true)
      end
    end
    after do
      Object.send(:remove_const, :WriteOnlyCustomResource)
    end

    subject { persister }
    let(:resource_class) { WriteOnlyCustomResource }
    let(:resource) { resource_class.new }

    it { is_expected.to respond_to(:save).with_keywords(:resource) }
    it { is_expected.to respond_to(:save_all).with_keywords(:resources) }
    it { is_expected.to respond_to(:delete).with_keywords(:resource) }

    it "can save a resource" do
      expect(persister.save(resource: resource)).to eq true
    end

    it "can save multiple resources at once" do
      resource2 = resource_class.new
      results = persister.save_all(resources: [resource, resource2])
      expect(results).to eq true
    end
  end
end
