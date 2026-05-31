# frozen_string_literal: true
require 'spec_helper'

describe ActiveTriples do
  describe '.class_from_string' do
    before do
      module TestModule
        class TestClass; end
      end

      class TestBase; end
    end
    
    after do
      Object.send(:remove_const, :TestModule)
      Object.send(:remove_const, :TestBase)
    end

    it 'converts classes in kernal' do
      expect(subject.class_from_string('TestBase')).to eq TestBase
    end

    it 'raises an error when class is undefined' do
      expect { subject.class_from_string('NotDefined') }
        .to raise_error NameError
    end

    it 'converts classes in a module' do
      expect(subject.class_from_string('TestClass', TestModule))
        .to eq TestModule::TestClass
    end

    it 'finds class above selected module' do
      expect(subject.class_from_string('Object', TestModule)).to eq Object
    end

    it 'raises an error when class is undefined in module' do
      expect { subject.class_from_string('NotDefined', TestModule) }
        .to raise_error NameError
    end

    it 'finds class above multiple selected modules' do
      expect(subject.class_from_string('Object', 'TestModule::TestClass'))
        .to eq Object
    end

    # is this the correct behavior!?
    it 'climbs up nested module contexts' do
      expect(subject.class_from_string('', 'TestModule::TestClass'))
        .to eq TestModule::TestClass
    end
  end
  
  describe '.ActiveTripels' do
    it 'outputs a string' do
      expect { described_class.ActiveTripels }.to output.to_stdout
    end
  end
end
