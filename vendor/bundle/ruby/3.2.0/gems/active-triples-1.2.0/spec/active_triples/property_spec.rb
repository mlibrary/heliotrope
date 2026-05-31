# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::Property do
  subject { described_class.new(options) }
  let(:options) do
    {
      :name => :title,
      :predicate => RDF::Vocab::DC.title,
      :class_name => "Test"
    }
  end

  it "should create accessors for each passed option" do
    expect(subject.name).to eq :title
    expect(subject.predicate).to eq RDF::Vocab::DC.title
    expect(subject.class_name).to eq "Test"
  end

  it 'should hold a block' do
    fake = Object.new
    property = described_class.new(options) do
      fake.configure
    end

    expect(fake).to receive(:configure)
    property.config.call
  end

  describe "#to_h" do
    it "should not return the property's name" do
      expect(subject.to_h).to eq (
        {
          :predicate => RDF::Vocab::DC.title,
          :class_name => "Test"
        }
      )
    end
  end

  it 'requires a :name' do
    expect { described_class.new({}) }.to raise_error(KeyError)
  end

  context '#cast' do
    it 'has a default of false' do
      expect(described_class.new(:name => :title).cast).to eq(false)
    end
    it 'allows for the default to be overridden' do
      expect(described_class.new(:name => :title, :cast => true).cast).to eq(true)
    end
  end
end
