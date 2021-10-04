# frozen_string_literal: true

require 'rails_helper'

class TestPolicy < ApplicationPolicy
  include AbilityHelpers
end

RSpec.describe AbilityHelpers do
  describe '#can?' do
    subject { policy.send(:can?, action) }

    let(:policy) { TestPolicy.new(agent, resource) }
    let(:action) { :action }
    let(:agent) { Anonymous.new({}) }
    let(:resource) { instance_double(Sighrax::Model, 'resource', publisher: publisher) }
    let(:publisher) { instance_double(Sighrax::Publisher, 'publisher', press: press) }
    let(:press) { instance_double(Press, 'press') }
    let(:platform_admin) { false }
    let(:press_role) { press_admin || press_editor || press_analyst }
    let(:press_admin) { false }
    let(:press_editor) { false }
    let(:press_analyst) { false }

    before do
      allow(Sighrax).to receive(:platform_admin?).with(agent).and_return platform_admin
      allow(Sighrax).to receive(:press_role?).with(agent, press).and_return press_role
      allow(Sighrax).to receive(:press_admin?).with(agent, press).and_return press_admin
      allow(Sighrax).to receive(:press_editor?).with(agent, press).and_return press_editor
      allow(Sighrax).to receive(:press_analyst?).with(agent, press).and_return press_analyst
    end

    it { expect { subject }.to raise_error(ArgumentError) }

    context 'when valid action' do
      context 'valid' do
        before { allow(ValidationService).to receive(:valid_action?).with(action).and_return true }

        it { is_expected.to be false }

        context 'when platform admin' do
          let(:platform_admin) { true }

          it { is_expected.to be true }
        end

        context 'when press role' do
          let(:press_admin) { true }
          let(:press_editor) { true }
          let(:press_analyst) { true }

          it { is_expected.to be false }
        end
      end

      context 'when create' do
        let(:action) { :create }

        it { is_expected.to be false }

        context 'when press admin' do
          let(:press_admin) { true }

          it { is_expected.to be true }
        end

        context 'when press editor' do
          let(:press_editor) { true }

          it { is_expected.to be true }
        end

        context 'when press analyst' do
          let(:press_analyst) { true }

          it { is_expected.to be false }
        end
      end

      context 'when read' do
        let(:action) { :read }

        it { is_expected.to be false }

        context 'when press admin' do
          let(:press_admin) { true }

          it { is_expected.to be true }
        end

        context 'when press editor' do
          let(:press_editor) { true }

          it { is_expected.to be true }
        end

        context 'when press analyst' do
          let(:press_analyst) { true }

          it { is_expected.to be true }
        end
      end

      context 'when update' do
        let(:action) { :update }

        it { is_expected.to be false }

        context 'when press admin' do
          let(:press_admin) { true }

          it { is_expected.to be true }
        end

        context 'when press editor' do
          let(:press_editor) { true }

          it { is_expected.to be true }
        end

        context 'when press analyst' do
          let(:press_analyst) { true }

          it { is_expected.to be false }
        end
      end

      context 'when delete' do
        let(:action) { :delete }

        it { is_expected.to be false }

        context 'when press admin' do
          let(:press_admin) { true }

          it { is_expected.to be true }
        end

        context 'when press editor' do
          let(:press_editor) { true }

          it { is_expected.to be true }
        end

        context 'when press analyst' do
          let(:press_analyst) { true }

          it { is_expected.to be false }
        end
      end
    end
  end
end
