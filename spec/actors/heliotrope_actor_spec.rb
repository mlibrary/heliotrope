# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/MessageSpies

describe HeliotropeActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env) { double('env', curation_concern: curation_concern, user: user, attributes: attributes) }
  let(:curation_concern) { double('curation_concern') }
  let(:user) { double('user') }
  let(:attributes) { double('attributes') }

  describe '#create' do
    subject { middleware.create(env) }

    before { allow(terminator).to receive(:create).with(env).and_return(success) }

    context 'success' do
      let(:success) { true }

      it do
        expect(Rails.logger).to receive(:info).with("callback before heliotrope actor create #{curation_concern} #{user}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor before create #{attributes}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor after create #{attributes}").ordered
        expect(Rails.logger).to receive(:info).with("callback after heliotrope actor create #{curation_concern} #{user}").ordered
        is_expected.to be true
      end
    end

    context 'fail' do
      let(:success) { false }

      it do
        expect(Rails.logger).to receive(:info).with("callback before heliotrope actor create #{curation_concern} #{user}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor before create #{attributes}").ordered
        is_expected.to be false
      end
    end
  end

  describe '#update' do
    subject { middleware.update(env) }

    before { allow(terminator).to receive(:update).with(env).and_return(success) }

    context 'success' do
      let(:success) { true }

      it do
        expect(Rails.logger).to receive(:info).with("callback before heliotrope actor update #{curation_concern} #{user}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor before update #{attributes}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor after update #{attributes}").ordered
        expect(Rails.logger).to receive(:info).with("callback after heliotrope actor update #{curation_concern} #{user}").ordered
        is_expected.to be true
      end
    end

    context 'fail' do
      let(:success) { false }

      it do
        expect(Rails.logger).to receive(:info).with("callback before heliotrope actor update #{curation_concern} #{user}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor before update #{attributes}").ordered
        is_expected.to be false
      end
    end
  end

  describe '#destroy' do
    subject { middleware.destroy(env) }

    before { allow(terminator).to receive(:destroy).with(env).and_return(success) }

    context 'success' do
      let(:success) { true }

      it do
        expect(Rails.logger).to receive(:info).with("callback before heliotrope actor destroy #{curation_concern} #{user}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor before destroy #{attributes}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor after destroy #{attributes}").ordered
        expect(Rails.logger).to receive(:info).with("callback after heliotrope actor destroy #{curation_concern} #{user}").ordered
        is_expected.to be true
      end
    end

    context 'fail' do
      let(:success) { false }

      it do
        expect(Rails.logger).to receive(:info).with("callback before heliotrope actor destroy #{curation_concern} #{user}").ordered
        expect(Rails.logger).to receive(:info).with("heliotrope actor before destroy #{attributes}").ordered
        is_expected.to be false
      end
    end
  end
end

# rubocop:enable RSpec/MessageSpies
