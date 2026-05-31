# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::NodeConfig do
  subject(:config) { described_class.new(term, predicate) }
  let(:predicate)  { RDF::URI(nil) }
  let(:term)       { :moomin }

  it { is_expected.to have_attributes(predicate: predicate, term: term) }

  describe '#[]' do
    subject(:config) { described_class.new(term, predicate, some_opt: :moomin) }

    it 'accesses arbitrary opts' do
      expect(config[:some_opt]).to eq :moomin
    end
  end

  describe '#cast' do
    it 'defaults to true' do
      expect { config.cast = false }
        .to change { config.cast }
        .from(true)
        .to(false)
    end

    it 'is set with the initializer' do
      expect(described_class.new(term, predicate, cast: false).cast).to be false
    end
  end

  describe '#with_index' do
    it 'yields an index configuration object' do
      expect { |b| config.with_index(&b) }
        .to yield_with_args(an_instance_of(described_class::IndexObject))
    end

    it 'accepts behavior settings' do
      config.with_index do |index|
        index.as :moomin, :snork
      end

      expect(config.behaviors).to contain_exactly :moomin, :snork
    end

    it 'accepts type settings' do
      config.with_index do |index|
        index.type :moomin
      end

      expect(config.type).to eq :moomin
    end
  end
end
