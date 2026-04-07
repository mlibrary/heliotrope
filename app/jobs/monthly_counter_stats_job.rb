# frozen_string_literal: true

require 'aws-sdk-s3'

class MonthlyCounterStatsJob < ApplicationJob
  queue_as :default

  # Configuration constants
  EARLIEST_RUN_DAY_OF_MONTH = 15  # Don't run before the 15th
  CLEANUP_RETENTION_MONTHS = 24   # Keep 24 months of statistics
  MAX_ERRORS_TO_LOG = 10          # Maximum processing errors to log

  # Fetch and process monthly counter statistics from SIQ
  # If target_date is provided, processes that month; otherwise processes previous month
  # Set force: true to reprocess existing statistics
  def perform(target_date = nil, force: false)
    target_date ||= Time.zone.today.prev_month
    year = target_date.year
    month = target_date.month

    # Only run if we're on or after the 15th of the current month
    unless Time.zone.today.day >= EARLIEST_RUN_DAY_OF_MONTH || force
      Rails.logger.info "MonthlyCounterStatsJob: Skipping - only runs on/after the #{EARLIEST_RUN_DAY_OF_MONTH}th of the month"
      return
    end

    Rails.logger.info "MonthlyCounterStatsJob: Checking for #{year}-#{format('%02d', month)} statistics"

    # Check if we already have stats for this period
    if !force && CounterSummary.exists_for_period?(year, month)
      Rails.logger.info "MonthlyCounterStatsJob: Statistics for #{year}-#{format('%02d', month)} already exist (use force: true to reprocess)"
      return
    end

    # Try to fetch and process the file from S3
    filename = "fulcrum_metric_totals-#{year}-#{format('%02d', month)}.csv"
    s3_key = "Exports/#{filename}"

    Dir.mktmpdir(['counter_stats', filename], Settings.scratch_space_path) do |dir|
      csv_path = File.join(dir, filename)
      fetch_result = fetch_from_s3(s3_key, csv_path)

      case fetch_result
      when true
        if process_and_save(csv_path, year, month, force: force)
          cleanup_old_statistics
          Rails.logger.info "MonthlyCounterStatsJob: Successfully processed #{filename}"
        end
      when :missing_file
        # File not found, send notification email
        Rails.logger.warn "MonthlyCounterStatsJob: File #{s3_key} not found in S3"
        CounterSummaryMailer.missing_file(year, month).deliver_now
      when :config_error
        # Config error already logged in load_config, just return
        return
      else
        Rails.logger.error "MonthlyCounterStatsJob: Failed to fetch #{s3_key} due to a non-missing-file error"
      end
    end
  rescue StandardError => e
    Rails.logger.error "MonthlyCounterStatsJob error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end

  private

    def fetch_from_s3(s3_key, destination_path)
      config = load_config
      return :config_error unless config

      begin
        # Pass credentials directly to S3 client to avoid global state pollution
        s3 = Aws::S3::Resource.new(
          region: config['BucketRegion'],
          credentials: Aws::Credentials.new(config['AwsAccessKeyId'], config['AwsSecretAccessKey'])
        )
        obj = s3.bucket(config['Bucket']).object(s3_key)

        # Download the file and let NoSuchKey indicate that it is missing
        obj.get(response_target: destination_path)
        true
      rescue Aws::S3::Errors::NoSuchKey
        :missing_file
      rescue Aws::S3::Errors::ServiceError => e
        Rails.logger.error "MonthlyCounterStatsJob: S3 error: #{e.message}"
        false
      end
    end

    def load_config
      config_path = Rails.root.join('config', 'scholarlyiq.yml')

      unless File.exist?(config_path)
        Rails.logger.error "MonthlyCounterStatsJob: Config file not found: #{config_path}"
        return nil
      end

      config = YAML.safe_load(File.read(config_path))

      unless config.is_a?(Hash)
        Rails.logger.error "MonthlyCounterStatsJob: Config file is empty or not a valid YAML mapping"
        return nil
      end

      # Validate required keys
      required_keys = %w[AwsAccessKeyId AwsSecretAccessKey Bucket BucketRegion]
      missing = required_keys - config.keys

      if missing.any?
        Rails.logger.error "MonthlyCounterStatsJob: Missing config keys: #{missing.join(', ')}"
        return nil
      end

      config
    rescue StandardError => e
      Rails.logger.error "MonthlyCounterStatsJob: Error loading config: #{e.message}"
      nil
    end

    def process_and_save(csv_path, year, month, force: false)
      start_time = Time.current

      processor = CounterSummaryService::CsvProcessor.new(year, month)
      monograph_stats = processor.process_file(csv_path)

      if processor.errors.any?
        Rails.logger.warn "MonthlyCounterStatsJob: Processing errors: #{processor.errors.first(MAX_ERRORS_TO_LOG).join(', ')}"
        if processor.errors.length > MAX_ERRORS_TO_LOG
          Rails.logger.warn "MonthlyCounterStatsJob: ... and #{processor.errors.length - MAX_ERRORS_TO_LOG} more errors"
        end
      end

      if monograph_stats.empty?
        Rails.logger.error "MonthlyCounterStatsJob: No statistics to save"
        return false
      end

      # Add timestamps for validated bulk creation
      now = Time.current
      stats_with_timestamps = monograph_stats.map do |stat|
        stat.merge(created_at: now, updated_at: now)
      end

      # Wrap deletion and creation in same transaction for data safety
      saved_count = 0
      CounterSummary.transaction do
        # Delete existing stats if forcing reprocessing
        if force
          existing_records = CounterSummary.for_period(year, month)
          if existing_records.exists?
            deleted_count = existing_records.delete_all
            Rails.logger.info "MonthlyCounterStatsJob: Deleted #{deleted_count} existing statistics for reprocessing"
          end
        end

        # Use validated saves so model constraints are enforced
        saved_records = CounterSummary.create!(stats_with_timestamps)
        # Handle both array and single object returns
        saved_count = saved_records.is_a?(Array) ? saved_records.length : 1
      end

      duration = Time.current - start_time
      Rails.logger.info "MonthlyCounterStatsJob: Saved #{saved_count} monograph statistics for #{year}-#{format('%02d', month)} in #{duration.round(2)}s"
      true
    rescue ActiveRecord::ActiveRecordError => e
      Rails.logger.error "MonthlyCounterStatsJob: Failed to save statistics: #{e.message}"
      raise # Re-raise to trigger job retry
    end

    def cleanup_old_statistics
      deleted_count = CounterSummary.cleanup_old_stats(CLEANUP_RETENTION_MONTHS)
      Rails.logger.info "MonthlyCounterStatsJob: Cleaned up #{deleted_count} old statistics records" if deleted_count > 0
    end
end
