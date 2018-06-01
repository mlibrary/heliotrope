# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PolicyResource do
  let(:policy_resource) { described_class.new(resource_class, resource) }
  let(:resource_class) { nil }
  let(:resource) { nil }

  describe '#resource_type' do
    subject { policy_resource.resource_type }

    it { expect { subject }.to raise_error(NoMethodError) }

    context 'User' do
      let(:resource_class) { User }

      it { is_expected.to eq('user') }
    end
  end

  describe '#resource_id' do
    subject { policy_resource.resource_id }

    it { expect { subject }.to raise_error(NoMethodError) }

    context 'User' do
      let(:resource_class) { User }

      it { is_expected.to eq('(all)') }

      context 'new' do
        let(:resource) { User.new }

        it { is_expected.to be nil }
      end

      context 'create' do
        let(:resource) { create(:user) }

        it { is_expected.to eq(resource.id) }
      end
    end
  end
end
