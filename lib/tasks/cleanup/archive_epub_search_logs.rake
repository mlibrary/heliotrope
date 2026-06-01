  # frozen_string_literal: true

  require 'csv'

  ########################################
  ## NOTE: THIS IS RUN FROM A CRON JOB! ##
  ########################################

  EPUB_SEARCH_LOG_ARCHIVE_DIR = File.join('/fulcrum', 'data', 'tmm', 'Fulcrum_Epub_Search_Log_Archives').freeze
  EPUB_SEARCH_LOG_ARCHIVE_HEADERS = %w[id noid query time hits press session_id user created_at search_results].freeze

  def ensure_archive_directory_exists!
    return if Dir.exist?(EPUB_SEARCH_LOG_ARCHIVE_DIR)

    fail "Epub search log archive directory not found at '#{EPUB_SEARCH_LOG_ARCHIVE_DIR}'"
  end

  def archive_filepath_for_month(year_month)
    File.join(EPUB_SEARCH_LOG_ARCHIVE_DIR, "#{year_month}_epub_search_logs.csv")
  end

  def with_archive_lock
    lockfile = File.join(EPUB_SEARCH_LOG_ARCHIVE_DIR, 'archive_epub_search_logs.lock')

    File.open(lockfile, File::RDWR | File::CREAT, 0o644) do |lock|
      unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        fail "archive_epub_search_logs appears to already be running (lock file: #{lockfile})"
      end

      begin
        yield
      ensure
        lock.flock(File::LOCK_UN)
      end
    end
  end

  def open_monthly_archive_csv(year_month)
    filepath = archive_filepath_for_month(year_month)
    file = File.open(filepath, 'ab:utf-8')
    csv = CSV.new(file)

    # Ensure each archive file is self-describing and can be parsed independently.
    csv << EPUB_SEARCH_LOG_ARCHIVE_HEADERS if file.size.zero?

    [file, csv, filepath]
  end

  def archive_old_epub_search_logs
    cutoff = Time.zone.now.months_ago(6).beginning_of_month
    scope = EpubSearchLog.where('created_at < ?', cutoff).order(:created_at, :id)

    archived_count = 0
    current_year_month = nil
    current_file = nil
    current_csv = nil
    current_filepath = nil

    begin
      # We only batch SELECTs to reduce memory pressure; deletes are still one row at a time.
      scope.find_each(batch_size: 1_000) do |log|
        year_month = log.created_at.in_time_zone.strftime('%Y-%m')

        if year_month != current_year_month
          current_file&.close
          current_file, current_csv, current_filepath = open_monthly_archive_csv(year_month)
          current_year_month = year_month
          puts "Archiving records into #{current_filepath}"
        end

        current_csv << [log.id, log.noid, log.query, log.time, log.hits, log.press, log.session_id, log.user, log.created_at, log.search_results]
        current_file.flush
        current_file.fsync

        # Delete only after the row has been written and flushed.
        log.delete
        archived_count += 1
      rescue StandardError => e
        Rails.logger.error("archive_epub_search_logs failed for EpubSearchLog #{log.id}: #{e.class}: #{e.message}")
      end
    ensure
      current_file&.close
    end

    puts "Archived and deleted #{archived_count} epub_search_logs records older than #{cutoff}."
  end

  desc 'Save epub_search_logs data to a file and then delete it from the database'
  namespace :heliotrope do
    task archive_epub_search_logs: :environment do
      ensure_archive_directory_exists!

      with_archive_lock do
        archive_old_epub_search_logs
      end
    end
  end
