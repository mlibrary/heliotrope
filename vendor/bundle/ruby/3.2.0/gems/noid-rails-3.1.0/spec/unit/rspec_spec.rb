# frozen_string_literal: true

require 'noid/rails/rspec'

RSpec.describe Noid::Rails::RSpec do
  include described_class

  let(:configured_minter) { @configured_minter }
  let(:var_name)          { :@original_minter }

  before do
    @configured_minter = Class.new(Noid::Rails::Minter::Base)
    @reset_minter      = Noid::Rails.config.minter_class

    Noid::Rails.configure do |noid_config|
      noid_config.minter_class = @configured_minter
    end
  end

  after do
    Noid::Rails.configure do |noid_config|
      noid_config.minter_class = @reset_minter
    end
  end

  describe '#disable_production_minter!' do
    it 'changes the configured minter' do
      expect { disable_production_minter! }
        .to change { Noid::Rails.config.minter_class }
        .from(configured_minter)
        .to described_class::DEFAULT_TEST_MINTER
    end

    it 'accepts custom test minter at call time' do
      my_minter = Class.new(Noid::Rails::Minter::Base)

      expect { disable_production_minter!(test_minter: my_minter) }
        .to change { Noid::Rails.config.minter_class }
        .from(configured_minter)
        .to my_minter
    end

    it 'does not overwrite stored minter on second call' do
      disable_production_minter!

      expect { disable_production_minter! }.not_to change { described_class.instance_variable_get(var_name) }
    end

    it 'still reenables after second call' do
      2.times { disable_production_minter! }
      expect { enable_production_minter! }
        .to change { Noid::Rails.config.minter_class }
        .from(described_class::DEFAULT_TEST_MINTER).to configured_minter
    end

    it 'disables after reenable' do
      disable_production_minter!
      enable_production_minter!
      expect { disable_production_minter! }
        .to change { Noid::Rails.config.minter_class }
        .from(configured_minter).to described_class::DEFAULT_TEST_MINTER
    end
  end

  describe '#enable_production_minter!' do
    it 'does nothing when already enabled' do
      expect { enable_production_minter! }
        .not_to change { Noid::Rails.config.minter_class }
    end

    context 'with minter disabled' do
      before { disable_production_minter! }

      it 'reenables the originally configured minter' do
        expect { enable_production_minter! }
          .to change { Noid::Rails.config.minter_class }
          .from(described_class::DEFAULT_TEST_MINTER)
          .to configured_minter
      end

      it 'enables after re-disable' do
        enable_production_minter!
        disable_production_minter!
        expect { enable_production_minter! }
          .to change { Noid::Rails.config.minter_class }
          .from(described_class::DEFAULT_TEST_MINTER).to configured_minter
      end
    end
  end
end
