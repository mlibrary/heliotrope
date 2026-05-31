# frozen_string_literal: true

require "yabeda"
require "yabeda/activejob/version"
require "active_support"

module Yabeda
  # Small set of metrics on activejob jobs
  module ActiveJob
    LONG_RUNNING_JOB_RUNTIME_BUCKETS = [
      0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, # standard (from Prometheus)
      30, 60, 120, 300, 1800, 3600, 21_600, # In cases jobs are very long-running
    ].freeze

    mattr_accessor :after_event_block, default: proc { |_event| }

    # rubocop: disable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize
    def self.install!
      Yabeda.configure do
        group :activejob

        counter :executed_total, tags: %i[queue activejob executions],
                                 comment: "A counter of the total number of activejobs executed."
        counter :enqueued_total, tags: %i[queue activejob executions],
                                 comment: "A counter of the total number of activejobs enqueued."
        counter :success_total, tags: %i[queue activejob executions],
                                comment: "A counter of the total number of activejobs successfully processed."
        counter :failed_total, tags: %i[queue activejob executions failure_reason],
                               comment: "A counter of the total number of jobs failed for an activejob."

        histogram :runtime, comment: "A histogram of the activejob execution time.",
                            unit: :seconds, per: :activejob,
                            tags: %i[queue activejob executions],
                            buckets: LONG_RUNNING_JOB_RUNTIME_BUCKETS

        histogram :latency, comment: "The job latency, the difference in seconds between enqueued and running time",
                            unit: :seconds, per: :activejob,
                            tags: %i[queue activejob executions],
                            buckets: LONG_RUNNING_JOB_RUNTIME_BUCKETS

        # job complete event
        ActiveSupport::Notifications.subscribe "perform.active_job" do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)
          labels = {
            activejob: event.payload[:job].class.to_s,
            queue: event.payload[:job].queue_name.to_s,
            executions: event.payload[:job].executions.to_s,
          }
          if event.payload[:exception].present?
            activejob_failed_total.increment(
              labels.merge(failure_reason: event.payload[:exception].first.to_s),
            )
          else
            activejob_success_total.increment(labels)
          end

          activejob_executed_total.increment(labels)
          activejob_runtime.measure(labels, Yabeda::ActiveJob.ms2s(event.duration))
          Yabeda::ActiveJob.after_event_block.call(event) if Yabeda::ActiveJob.after_event_block.respond_to?(:call)
        end

        # start job event
        ActiveSupport::Notifications.subscribe "perform_start.active_job" do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)

          labels = {
            activejob: event.payload[:job].class.to_s,
            queue: event.payload[:job].queue_name,
            executions: event.payload[:job].executions.to_s,
          }

          labels.merge!(event.payload.slice(*Yabeda.default_tags.keys - labels.keys))
          job_latency = Yabeda::ActiveJob.job_latency(event)
          activejob_latency.measure(labels, job_latency) if job_latency.present?
          Yabeda::ActiveJob.after_event_block.call(event) if Yabeda::ActiveJob.after_event_block.respond_to?(:call)
        end

        ActiveSupport::Notifications.subscribe "enqueue.active_job" do |*args|
          event = ActiveSupport::Notifications::Event.new(*args)

          labels = {
            activejob: event.payload[:job].class.to_s,
            queue: event.payload[:job].queue_name,
            executions: event.payload[:job].executions.to_s,
          }

          labels.merge!(event.payload.slice(*Yabeda.default_tags.keys - labels.keys))
          activejob_enqueued_total.increment(labels)
          Yabeda::ActiveJob.after_event_block.call(event) if Yabeda::ActiveJob.after_event_block.respond_to?(:call)
        end
      end
    end
    # rubocop: enable Metrics/MethodLength, Metrics/BlockLength, Metrics/AbcSize

    def self.job_latency(event)
      enqueue_time = event.payload[:job].enqueued_at
      return nil unless enqueue_time.present?

      enqueue_time = Time.parse(enqueue_time).utc unless enqueue_time.is_a?(Time)
      perform_at_time = Time.parse(event.end.to_s).utc
      (perform_at_time - enqueue_time)
    end

    def self.ms2s(milliseconds)
      (milliseconds.to_f / 1000).round(3)
    end
  end
end
