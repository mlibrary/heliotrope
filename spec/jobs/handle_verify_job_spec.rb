# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HandleVerifyJob, type: :job do
  include ActiveJob::TestHelper

  let(:model_id) { 'validnoid' }

  describe 'job queue' do
    subject(:job) { described_class.perform_later(model_id) }

    after do
      clear_enqueued_jobs
      clear_performed_jobs
    end

    it 'queues the job' do
      expect { job }.to have_enqueued_job(described_class).with(model_id).on_queue("default")
    end

    it 'executes perform' do
      perform_enqueued_jobs { job }
    end
  end

  context 'job' do
    let(:job) { described_class.new }

    describe '#perform' do
      subject { job.perform(model_id) }

      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }
      let(:not_found_msg) { "HandleVerifyJob #{model_id} handle deposit record NOT found!" }
      let(:error_msg) { "HandleVerifyJob #{model_id} StandardError" }

      before do
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:warn).with(not_found_msg)
        allow(logger).to receive(:error).with(error_msg)
      end

      it 'logs warnings' do
        is_expected.to be false
        expect(logger).to have_received(:warn).with(not_found_msg)
        expect(logger).not_to have_received(:error).with(error_msg)
      end

      context 'when model' do
        let(:record) { nil }

        before do
          allow(HandleDeposit).to receive(:find_by).with(noid: model_id).and_return(record)
        end

        it 'nil record' do
          is_expected.to be false
          expect(logger).to have_received(:warn).with(not_found_msg)
          expect(logger).not_to have_received(:error).with(error_msg)
        end

        context 'when record' do
          let(:record) { instance_double(HandleDeposit, 'record', noid: model_id, action: 'action', verified: verified) }
          let(:verified) { true }
          let(:boolean) { double('boolean') }

          before do
            allow(HandleDeposit).to receive(:find_by).with(noid: model_id).and_return(record)
            allow(job).to receive(:verify_handle).with(record.action, model_id).and_return(boolean)
          end

          it 'does nothing' do
            is_expected.to be true
            expect(job).not_to have_received(:verify_handle).with(record.action, model_id)
            expect(logger).not_to have_received(:warn).with(not_found_msg)
            expect(logger).not_to have_received(:error).with(error_msg)
          end

          context 'when not verified' do
            let(:verified) { false }

            before do
              allow(record).to receive(:verified=).with(boolean)
              allow(record).to receive(:save!)
            end

            it 'returns verify handle' do
              is_expected.to be boolean
              expect(job).to have_received(:verify_handle).with(record.action, model_id)
              expect(record).to have_received(:verified=).with(boolean)
              expect(record).to have_received(:save!)
              expect(logger).not_to have_received(:warn).with(not_found_msg)
              expect(logger).not_to have_received(:error).with(error_msg)
            end

            context 'standard error' do
              before { allow(record).to receive(:save!).and_raise(StandardError) }

              it 'returns' do
                is_expected.to be false
                expect(job).to have_received(:verify_handle).with(record.action, model_id)
                expect(record).to have_received(:verified=).with(boolean)
                expect(record).to have_received(:save!)
                expect(logger).not_to have_received(:warn).with(not_found_msg)
                expect(logger).to have_received(:error).with(error_msg)
              end
            end
          end
        end
      end
    end

    describe '#verify_handle' do
      subject { job.verify_handle(action, model_id) }

      let(:action) { 'action' }
      let(:boolean) { double('boolean') }
      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }
      let(:error_msg) { "HandleVerifyJob #{model_id} action #{action} invalid!!!" }


      before do
        allow(job).to receive(:verify_handle_create).with(model_id).and_return(boolean)
        allow(job).to receive(:verify_handle_delete).with(model_id).and_return(boolean)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error).with(error_msg)
      end

      it 'logs error' do
        is_expected.to be false
        expect(job).not_to have_received(:verify_handle_create).with(model_id)
        expect(job).not_to have_received(:verify_handle_delete).with(model_id)
        expect(logger).to have_received(:error).with(error_msg)
      end

      context 'when action create' do
        let(:action) { 'create' }

        it 'verify handle create' do
          is_expected.to be boolean
          expect(job).to have_received(:verify_handle_create).with(model_id)
          expect(job).not_to have_received(:verify_handle_delete).with(model_id)
          expect(logger).not_to have_received(:error).with(error_msg)
        end
      end

      context 'when action delete' do
        let(:action) { 'delete' }

        it 'verify handle delete' do
          is_expected.to be boolean
          expect(job).not_to have_received(:verify_handle_create).with(model_id)
          expect(job).to have_received(:verify_handle_delete).with(model_id)
          expect(logger).not_to have_received(:error).with(error_msg)
        end
      end
    end

    describe '#verify_handle_create' do
      subject { job.verify_handle_create(model_id) }

      let(:model) { instance_double(Sighrax::Model, 'model', noid: model_id) }
      let(:model_url) { "https://www.test.com/#{model.noid}" }
      let(:service_url) { 'url' }
      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }
      let(:error_msg) { "HandleVerifyJob #{model.noid} verify handle create StandardError" }

      before do
        allow(Sighrax).to receive(:from_noid).with(model_id).and_return(model)
        allow(Sighrax).to receive(:url).with(model).and_return(model_url)
        allow(HandleNet).to receive(:value).with(model.noid).and_return(service_url)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error).with(error_msg)
      end

      it 'not verified' do
        is_expected.to be false
        expect(logger).not_to have_received(:error).with(error_msg)
      end

      context 'verified' do
        let(:service_url) { model_url }

        it 'urls match' do
          is_expected.to be true
          expect(logger).not_to have_received(:error).with(error_msg)
        end

        context 'when standard error' do
          before { allow(HandleNet).to receive(:value).with(model.noid).and_raise(StandardError) }

          it 'not verified and logs error' do
            is_expected.to be false
            expect(logger).to have_received(:error).with(error_msg)
          end
        end
      end
    end

    describe '#verify_handle_delete' do
      subject { job.verify_handle_delete(model_id) }

      let(:service_url) { ['url'] }
      let(:logger) { instance_double(ActiveSupport::Logger, 'logger') }
      let(:error_msg) { "HandleVerifyJob #{model_id} verify handle delete StandardError" }

      before do
        allow(HandleNet).to receive(:value).with(model_id).and_return(service_url)
        allow(Rails).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error).with(error_msg)
      end

      it 'not verified' do
        is_expected.to be false
        expect(logger).not_to have_received(:error).with(error_msg)
      end

      context 'verified' do
        let(:service_url) { [] } # handle deleted/non-existent, returns empty array

        it 'handle not found' do
          is_expected.to be true
          expect(logger).not_to have_received(:error).with(error_msg)
        end

        context 'when standard error' do
          before { allow(HandleNet).to receive(:value).with(model_id).and_raise(StandardError) }

          it 'not verified and logs error' do
            is_expected.to be false
            expect(logger).to have_received(:error).with(error_msg)
          end
        end
      end
    end
  end
end
