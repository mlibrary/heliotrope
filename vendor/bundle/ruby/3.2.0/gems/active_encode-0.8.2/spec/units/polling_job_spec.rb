# frozen_string_literal: true
require 'rails_helper'

describe ActiveEncode::PollingJob do
  include ActiveJob::TestHelper

  before do
    class PollingEncode < ActiveEncode::Base
      include ActiveEncode::Polling
      after_status_update ->(encode) { encode.history << "PollingEncode ran after_status_update" }
      after_failed ->(encode) { encode.history << "PollingEncode ran after_failed" }
      after_cancelled ->(encode) { encode.history << "PollingEncode ran after_cancelled" }
      after_completed ->(encode) { encode.history << "PollingEncode ran after_completed" }

      def history
        @history ||= []
      end
    end
  end

  after do
    Object.send(:remove_const, :PollingEncode)
  end

  describe '#perform' do
    subject { encode.history }
    let(:encode) { PollingEncode.create("sample.mp4").tap { |encode| encode.state = state } }
    let(:poll) { described_class.new }

    before do
      encode
      clear_enqueued_jobs
      poll.perform(encode)
    end

    context "with job failed" do
      let(:state) { :failed }

      it "runs after_failed" do
        is_expected.to include("PollingEncode ran after_status_update")
        is_expected.to include("PollingEncode ran after_failed")
      end

      it "does not re-enqueue itself" do
        expect(described_class).not_to have_been_enqueued
      end
    end

    context "with job cancelled" do
      let(:state) { :cancelled }

      it "runs after_cancelled" do
        is_expected.to include("PollingEncode ran after_status_update")
        is_expected.to include("PollingEncode ran after_cancelled")
      end

      it "does not re-enqueue itself" do
        expect(described_class).not_to have_been_enqueued
      end
    end

    context "with job completed" do
      let(:state) { :completed }

      it "runs after_completed" do
        is_expected.to include("PollingEncode ran after_status_update")
        is_expected.to include("PollingEncode ran after_completed")
      end

      it "does not re-enqueue itself" do
        expect(described_class).not_to have_been_enqueued
      end
    end

    context "with job running" do
      let(:state) { :running }

      it "runs after_status_update" do
        is_expected.to include("PollingEncode ran after_status_update")
      end

      it "re-enqueues itself" do
        expect(described_class).to have_been_enqueued.with(encode)
      end
    end
  end
end
