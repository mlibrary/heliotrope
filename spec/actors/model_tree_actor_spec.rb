# frozen_string_literal: true

require 'rails_helper'

describe ModelTreeActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env) { double('env', curation_concern: curation_concern) }
  let(:curation_concern) { double('curation_concern', id: noid) }
  let(:noid) { 'validnoid' }
  let(:model_tree_service) { instance_double(ModelTreeService, 'model_tree_service') }

  before { allow(ModelTreeService).to receive(:new).and_return(model_tree_service) }

  describe '#destroy' do
    subject { middleware.destroy(env) }

    before { allow(model_tree_service).to receive(:unlink).with(noid) }

    context 'next_actor.destroy(env) returns true' do
      before { allow(terminator).to receive(:destroy).with(env).and_return(true) }

      it 'unlinks model from tree' do
        is_expected.to be true
        expect(model_tree_service).to have_received(:unlink).with(noid)
      end

      context 'error' do
        let(:message) { "ERROR: ModelTreeActor.destroy(#{env}) error StandardError" }

        before do
          allow(curation_concern).to receive(:id).and_raise(StandardError)
          allow(Rails.logger).to receive(:error).with(message)
        end

        it 'logs error, does NOT unlink model, but allows stack to continue' do
          is_expected.to be true
          expect(model_tree_service).not_to have_received(:unlink).with(noid)
          expect(Rails.logger).to have_received(:error).with(message)
        end
      end
    end

    context 'next_actor.destroy(env) returns false' do
      before { allow(terminator).to receive(:destroy).with(env).and_return(false) }

      it 'unlinks model from tree' do
        is_expected.to be false
        expect(model_tree_service).to have_received(:unlink).with(noid)
      end

      context 'error' do
        let(:message) { "ERROR: ModelTreeActor.destroy(#{env}) error StandardError" }

        before do
          allow(curation_concern).to receive(:id).and_raise(StandardError)
          allow(Rails.logger).to receive(:error).with(message)
        end

        it 'logs error, does NOT unlink model, but allows stack to continue' do
          is_expected.to be false
          expect(model_tree_service).not_to have_received(:unlink).with(noid)
          expect(Rails.logger).to have_received(:error).with(message)
        end
      end
    end
  end
end
