# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Keycard::Request::MemoizedAttributes do
  # A stand-in for Keycard::InstitutionFinder that records how often it is asked.
  let(:finder) do
    Class.new do
      attr_reader :calls

      def initialize
        @calls = 0
      end

      def identity_keys
        [:dlpsInstitutionId]
      end

      def attributes_for(_request)
        @calls += 1
        { dlpsInstitutionId: [42] }
      end
    end.new
  end

  let(:request) { double('request', env: {}) }
  let(:attributes) { Keycard::Request::Attributes.new(request, finders: [finder]) }

  describe 'without the override' do
    it 'consults the finders on every read' do
      3.times { attributes[:dlpsInstitutionId] }

      expect(finder.calls).to eq 3
    end
  end

  describe 'with the override' do
    before { attributes.extend(described_class) }

    it 'consults the finders exactly once no matter how many keys are read' do
      attributes[:dlpsInstitutionId]
      attributes[:user_pid]
      attributes.all
      attributes.identity
      attributes.supplemental

      expect(finder.calls).to eq 1
    end

    it 'returns the same values the gem would have' do
      memoized = attributes.all
      plain = Keycard::Request::Attributes.new(request, finders: [finder]).all

      expect(memoized).to eq plain
    end

    it 'still resolves individual keys' do
      expect(attributes[:dlpsInstitutionId]).to eq [42]
    end

    it 'freezes the result so it cannot be corrupted by a caller' do
      expect(attributes.all).to be_frozen
    end

    it 'does not leak between instances' do
      attributes.all
      other = Keycard::Request::Attributes.new(request, finders: [finder]).extend(described_class)
      other.all

      expect(finder.calls).to eq 2
    end
  end
end

RSpec.describe Keycard::Request::MemoizingAttributesFactory do
  subject(:factory) { described_class.new(finders: []) }

  let(:request) { double('request', env: {}) }

  it 'is a drop-in for the gem factory' do
    expect(factory).to be_a Keycard::Request::AttributesFactory
  end

  it 'builds attributes that memoize' do
    expect(factory.for(request)).to be_a Keycard::Request::MemoizedAttributes
  end

  it 'still honours the configured access mode' do
    allow(Keycard.config).to receive(:access).and_return(:shibboleth)

    expect(factory.for(request)).to be_a Keycard::Request::ShibbolethAttributes
  end

  it 'falls back to direct attributes for an unknown access mode' do
    allow(Keycard.config).to receive(:access).and_return(:nonsense)

    expect(factory.for(request)).to be_a Keycard::Request::DirectAttributes
  end
end
