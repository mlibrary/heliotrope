# frozen_string_literal: true
RSpec.shared_examples 'a Valkyrie::ChangeSet' do |*_flags|
  before do
    raise 'adapter must be set with `let(:change_set)`' unless defined? change_set
    raise 'change_set must have at least one field' if change_set.fields.empty?
  end

  subject { change_set }

  it { is_expected.to respond_to :append_id }
  it { is_expected.to respond_to :fields }
  it { is_expected.to respond_to :fields= }
  it { is_expected.to respond_to :multiple? }
  it { is_expected.to respond_to :prepopulate! }
  it { is_expected.to respond_to :required? }
  it { is_expected.to respond_to :validate }
  it { is_expected.to respond_to :valid? }

  it "can set an append_id" do
    change_set.append_id = Valkyrie::ID.new("test")
    expect(change_set.append_id).to eq Valkyrie::ID.new("test")
    expect(change_set[:append_id]).to eq Valkyrie::ID.new("test")
  end

  describe "#fields" do
    it "returns an hash" do
      expect(change_set.fields).to be_a Hash
    end
  end

  describe "#fields=" do
    it "sets fields" do
      change_set.fields = { "totally_a_field" => [] }
      expect(change_set.fields).to eq("totally_a_field" => [])
    end
  end

  describe "#multiple?" do
    it "returns a boolean" do
      expect(change_set.multiple?(change_set.fields.keys.first)).to be_in [true, false]
    end
  end

  describe "#prepopulate!" do
    it "doesn't make it look changed" do
      expect(change_set).not_to be_changed
      change_set.prepopulate!
      expect(change_set).not_to be_changed
    end
  end

  describe "#required?" do
    it "returns a boolean" do
      expect(change_set.required?(change_set.fields.keys.first)).to be_in [true, false]
    end
  end

  describe "#valid?" do
    it "returns a boolean" do
      expect(change_set.valid?).to be_in [true, false]
    end
  end

  describe "#validate" do
    it "returns a change_set" do
      expect(change_set.validate(change_set.fields)).to be_in [true, false]
    end
  end

  describe ".validators_on" do
    it "the class responds to validators_on" do
      expect(described_class).to respond_to(:validators_on)
    end
  end

  describe "#optimistic_locking_enabled?" do
    it "delegates down to the resource" do
      expect(change_set.optimistic_locking_enabled?).to eq change_set.resource.optimistic_locking_enabled?
    end
  end
end
