# frozen_string_literal: true

require 'rails_helper'

class TestPolicy  < ApplicationPolicy
  include AbilityHelpers
end

RSpec.describe AbilityHelpers do
  describe '#can?' do
    subject { policy.send(:can?, :action) }

    let(:policy) { TestPolicy.new(agent, resource) }
    let(:action) { :action }
    let(:agent) { Anonymous.new({}) }
    let(:resource) { instance_double(Sighrax::Model, 'resource') }
    let(:platform_admin) { false }
    let(:ability_can) { false }

    before do
      allow(Sighrax).to receive(:platform_admin?).with(agent).and_return platform_admin
      allow(Sighrax).to receive(:ability_can?).with(agent, action, resource).and_return ability_can
    end

    it { is_expected.to be false }

    context 'when platform admin' do
      let(:platform_admin) { true }

      it { is_expected.to be true }
    end

    context 'when ability can' do
      let(:ability_can) { true }

      it { is_expected.to be true }
    end
  end
end
