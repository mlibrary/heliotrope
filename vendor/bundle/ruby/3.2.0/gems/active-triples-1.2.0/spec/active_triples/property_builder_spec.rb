# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::PropertyBuilder do
  subject         { described_class.new(name, options) }
  let(:name)      { :moomin }
  let(:predicate) { :predicate_uri }
  let(:options)   { { predicate: predicate } }

  it { is_expected.to have_attributes(name:    name) }
  it { is_expected.to have_attributes(options: options) }

  describe '#build' do
    it 'gives a config for name' do
      expect(subject.build)
        .to have_attributes(term: name, predicate: predicate)
    end
    
    it 'yields an IndexObject' do
      expect { |b| subject.build(&b) }.to yield_control
    end
  end

  describe '.create_builder' do
    it 'raises when property name is not a symbol' do
      expect { described_class.create_builder('name', options) }
        .to raise_error ArgumentError
    end

    it 'raises when predicate is invalid' do
      options[:predicate] = Time.now
      expect { described_class.create_builder(name, options) }
        .to raise_error ArgumentError
    end
  end
end
