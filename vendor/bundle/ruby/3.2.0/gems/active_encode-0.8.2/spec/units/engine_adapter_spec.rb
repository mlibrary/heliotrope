# frozen_string_literal: true
require 'spec_helper'

describe ActiveEncode::EngineAdapter do
  before do
    module ActiveEncode
      module EngineAdapters
        class StubOneAdapter
          def create(_); end

          def find(_, _ = {}); end

          def cancel(_encode); end
        end

        class StubTwoAdapter
          def create(_encode); end

          def find(_id, _opts = {}); end

          def cancel(_encode); end
        end
      end
    end
  end

  after do
    ActiveEncode::EngineAdapters.send(:remove_const, :StubOneAdapter)
    ActiveEncode::EngineAdapters.send(:remove_const, :StubTwoAdapter)
  end

  it 'does not allow classes as arguments' do
    expect { ActiveEncode::Base.engine_adapter = ActiveEncode::EngineAdapters::StubOneAdapter }.to raise_error(ArgumentError)
  end

  it 'does not allow arguments that are not engine adapters' do
    expect { ActiveEncode::Base.engine_adapter = Mutex.new }.to raise_error(ArgumentError)
  end

  context 'overriding' do
    let(:base_engine_adapter) { ActiveEncode::Base.engine_adapter }

    it 'does not affect the parent' do
      child_encode_one = Class.new(ActiveEncode::Base)
      child_encode_one.engine_adapter = :stub_one

      expect(child_encode_one.engine_adapter).not_to eq base_engine_adapter
      expect(child_encode_one.engine_adapter).to be_kind_of ActiveEncode::EngineAdapters::StubOneAdapter
      expect(ActiveEncode::Base.engine_adapter).to eq base_engine_adapter
    end

    it 'does not affect its sibling' do
      child_encode_one = Class.new(ActiveEncode::Base)
      child_encode_one.engine_adapter = :stub_one
      child_encode_two = Class.new(ActiveEncode::Base)
      child_encode_two.engine_adapter = :stub_two

      expect(child_encode_two.engine_adapter).not_to eq base_engine_adapter
      expect(child_encode_two.engine_adapter).to be_kind_of ActiveEncode::EngineAdapters::StubTwoAdapter
      # child_encode_one's engine adapter should remain unchanged
      expect(child_encode_one.engine_adapter).to be_kind_of ActiveEncode::EngineAdapters::StubOneAdapter
      expect(ActiveEncode::Base.engine_adapter).to eq base_engine_adapter
      # new encodes should not be affected
      expect(Class.new(ActiveEncode::Base).engine_adapter).to eq base_engine_adapter
    end
  end
end
