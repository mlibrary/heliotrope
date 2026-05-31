# frozen_string_literal: true
RSpec.shared_examples 'a Valkyrie::Resource' do
  before do
    raise 'resource_klass must be set with `let(:resource_klass)`' unless
      defined? resource_klass
  end
  let(:meta_klass) do
    Class.new(resource_klass)
  end
  describe "#id" do
    it "can be set via instantiation and casts to a Valkyrie::ID" do
      resource = meta_klass.new(id: "test")
      expect(resource.id).to eq Valkyrie::ID.new("test")
    end

    it "is nil when not set" do
      resource = meta_klass.new
      expect(resource.id).to be_nil
    end

    it { is_expected.to respond_to(:persisted?).with(0).arguments }
    it { is_expected.to respond_to(:to_param).with(0).arguments }
    it { is_expected.to respond_to(:to_model).with(0).arguments }
    it { is_expected.to respond_to(:model_name).with(0).arguments }
    it { is_expected.to respond_to(:column_for_attribute).with(1).arguments }

    describe "#has_attribute?" do
      it "returns true when it has a given attribute" do
        resource = meta_klass.new
        expect(resource.has_attribute?(:id)).to eq true
      end
    end

    describe ".fields" do
      it "returns a set of fields" do
        expect(meta_klass).to respond_to(:fields).with(0).arguments
        expect(meta_klass.fields).to include(:id)
      end
    end

    describe "#attributes" do
      it "returns a list of all set attributes" do
        resource = meta_klass.new(id: "test")
        expect(resource.attributes[:id].to_s).to eq "test"
      end
    end
  end

  describe "#internal_resource" do
    it "is set to the resource's class on instantiation" do
      resource = meta_klass.new
      expect(resource.internal_resource).to eq meta_klass.to_s
    end
  end

  describe "#human_readable_type" do
    before do
      class Valkyrie::Specs::MyCustomResource < Valkyrie::Resource
        attribute :title, Valkyrie::Types::Set
      end
    end

    after do
      Valkyrie::Specs.send(:remove_const, :MyCustomResource)
    end

    subject(:my_custom_resource) { Valkyrie::Specs::MyCustomResource.new }

    it "returns a human readable rendering of the resource class" do
      expect(my_custom_resource.human_readable_type).to eq "My Custom Resource"
    end
  end

  describe "#[]" do
    it "allows access to properties which are set" do
      meta_klass.attribute :my_property unless meta_klass.schema.key?(:my_property)
      resource = meta_klass.new

      resource.my_property = "test"

      expect(resource[:my_property]).to eq ["test"]

      unset_key(meta_klass, :my_property)
    end
    it "returns nil for non-existent properties" do
      resource = meta_klass.new

      expect(resource[:bad_property]).to eq nil
    end
    it "can be accessed via a string" do
      meta_klass.attribute :other_property unless meta_klass.schema.key?(:other_property)
      resource = meta_klass.new

      resource.other_property = "test"

      expect(resource["other_property"]).to eq ["test"]

      unset_key(meta_klass, :other_property)
    end
  end

  def unset_key(meta_klass, property)
    meta_klass.schema(Dry::Types::Schema.new(Hash, **meta_klass.schema.options, keys: meta_klass.schema.keys.select { |x| x.name != property }, meta: meta_klass.schema.meta))
    meta_klass.instance_variable_set(:@attribute_names, nil)
    meta_klass.allow_nonexistent_keys
  end

  describe "#set_value" do
    it "can set a value" do
      meta_klass.attribute :set_value_property unless meta_klass.schema.key?(:set_value_property)
      resource = meta_klass.new

      resource.set_value(:set_value_property, "test")

      expect(resource.set_value_property).to eq ["test"]
      resource.set_value("set_value_property", "testing")
      expect(resource.set_value_property).to eq ["testing"]
      unset_key(meta_klass, :set_value_property)
    end
  end

  describe ".new" do
    it "can set values with symbols" do
      meta_klass.attribute :symbol_property unless meta_klass.schema.key?(:symbol_property)

      resource = meta_klass.new(symbol_property: "bla")

      expect(resource.symbol_property).to eq ["bla"]
      unset_key(meta_klass, :symbol_property)
    end
    it "can not set values with string properties" do
      meta_klass.attribute :string_property unless meta_klass.schema.key?(:string_property)

      resource = nil
      expect(resource).not_to respond_to :string_property
      unset_key(meta_klass, :string_property)
    end
  end

  describe "#attributes" do
    it "returns all defined attributs, including nil keys" do
      meta_klass.attribute :bla unless meta_klass.schema.key?(:bla)

      resource = meta_klass.new

      expect(resource.attributes).to be_frozen
      expect(resource.attributes).to have_key(:bla)
      expect(resource.attributes[:internal_resource]).to eq meta_klass.to_s
      expect { resource.attributes.dup[:internal_resource] = "bla" }.not_to output.to_stderr

      unset_key(meta_klass, :bla)
      resource = meta_klass.new
      expect(resource.attributes).not_to have_key(:bla)
      expect(resource.as_json).not_to have_key(:bla)
    end
  end

  describe "#__attributes__" do
    it "returns all defined attributes, but doesn't add nil keys" do
      meta_klass.attribute :bla unless meta_klass.schema.key?(:bla)

      resource = meta_klass.new
      expect(resource.__attributes__).to be_frozen
      expect(resource.__attributes__).not_to have_key :bla
      expect(resource.__attributes__).to have_key :internal_resource

      unset_key(meta_klass, :bla)
    end
  end
end
