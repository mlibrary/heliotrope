# frozen_string_literal: true
RSpec.shared_examples 'a Valkyrie::ChangeSetPersister' do |*_flags|
  before do
    raise 'adapter must be set with `let(:change_set_persister)`' unless defined? change_set_persister
    class Valkyrie::Specs::CustomResource < Valkyrie::Resource
      include Valkyrie::Resource::AccessControls
      attribute :title
      attribute :member_ids
      attribute :nested_resource
    end

    class Valkyrie::Specs::CustomChangeSet < Valkyrie::ChangeSet
      self.fields = [:title]
    end
  end
  after do
    Valkyrie::Specs.send(:remove_const, :CustomResource)
    Valkyrie::Specs.send(:remove_const, :CustomChangeSet)
  end

  subject { change_set_persister }
  let(:resource_class) { Valkyrie::Specs::CustomResource }
  let(:resource) { resource_class.new }
  let(:change_set) { Valkyrie::Specs::CustomChangeSet.new(resource) }

  it { is_expected.to respond_to(:save).with_keywords(:change_set) }
  it { is_expected.to respond_to(:save_all).with_keywords(:change_sets) }
  it { is_expected.to respond_to(:delete).with_keywords(:change_set) }
  it { is_expected.to respond_to(:metadata_adapter) }
  it { is_expected.to respond_to(:storage_adapter) }

  describe "#save" do
    it "saves a resource and returns it" do
      output = subject.save(change_set: change_set)

      expect(output).to be_kind_of Valkyrie::Specs::CustomResource
      expect(output).to be_persisted
    end
  end

  describe "#delete" do
    it "deletes a resource" do
      output = subject.save(change_set: change_set)
      subject.delete(change_set: Valkyrie::Specs::CustomChangeSet.new(output))

      expect do
        subject.metadata_adapter.query_service.find_by(id: output.id)
      end.to raise_error Valkyrie::Persistence::ObjectNotFoundError
    end
  end

  describe "#save_all" do
    it "saves multiple change_sets and returns them" do
      change_set2 = Valkyrie::Specs::CustomChangeSet.new(resource_class.new)
      output = subject.save_all(change_sets: [change_set, change_set2])

      expect(output.map(&:id).compact.length).to eq 2
    end
  end
end
