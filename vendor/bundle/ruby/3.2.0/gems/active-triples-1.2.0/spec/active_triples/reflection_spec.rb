# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples::Reflection do
  subject { klass.new }

  let(:klass) { Class.new { include ActiveTriples::Reflection } }

  let(:config_hash) do
    { 'moomin' => double('moomin config'),
      'snorkmaiden' => double('snorkmaiden config') }
  end

  describe '#reflections' do
    it 'gives reflections for the instance' do
      expect(subject.reflections).to eq klass
    end
  end

  describe '.properties=' do
    it 'sets properties' do
      expect { klass.properties = config_hash }
        .to change { klass._active_triples_config }.to config_hash
    end
  end
  
  describe '.properties' do
    it 'gets the set properties' do
      klass.properties = config_hash

      expect(klass.properties).to eq config_hash
    end
  end

  describe '.has_property?' do
    before { klass.properties = config_hash }

    it 'returns true for properties it has' do
      klass._active_triples_config.each do |property, _| 
        expect(klass).to have_property property
      end
    end

    it 'coerces to a string' do
      klass._active_triples_config.each do |property, _| 
        expect(klass).to have_property property.to_sym
      end
    end

    it 'returns false for unregistered properties' do
      expect(klass).not_to have_property 'moominmama'
    end
  end

  describe '.reflect_on_property' do
    before { klass.properties = config_hash }

    it 'gets the config for the requested property' do
      klass._active_triples_config.each do |property, config| 
        expect(klass.reflect_on_property(property)).to eq config
      end
    end

    it 'coerces to a string' do
      klass._active_triples_config.each do |property, config| 
        expect(klass.reflect_on_property(property.to_sym)).to eq config
      end
    end

    it 'raises an error on unregistered properties' do
      expect { klass.reflect_on_property(:fake) }.to raise_error do |err|
        expect(err).to be_a ActiveTriples::UndefinedPropertyError
        expect(err.klass).to eq klass
        expect(err.property).to eq :fake.to_s
      end
    end
  end
end
