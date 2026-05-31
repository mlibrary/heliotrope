# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ActiveTriples::ExtensionStrategy do
  subject { described_class }

  describe ".apply" do
    it "should copy the property to the asset" do
      asset = build_asset
      property = build_property("name", {:predicate => RDF::Vocab::DC.title})

      subject.apply(asset, property)

      expect(asset).to have_received(:property).with(property.name, property.to_h)
    end

    it 'execute the block' do
      block = Proc.new {}
      asset = build_asset
      property = build_property("name", {:predicate => RDF::Vocab::DC.title}, &block)

      subject.apply(asset, property)

      expect(asset).to have_received(:property).with(property.name, property.to_h, &block)
    end

    def build_asset
      object_double(ActiveTriples::Resource, :property => nil)
    end

    def build_property(name, options, &block)
      property = object_double(ActiveTriples::Property.new(:name => nil))
      allow(property).to receive(:name).and_return(name)
      allow(property).to receive(:to_h).and_return(options)
      allow(property).to receive(:config).and_return(block)
      property
    end
  end
end
