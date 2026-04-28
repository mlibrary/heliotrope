# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength
namespace :counter_summary do
  desc 'Import historical counter statistics CSV files from a directory'
  task :import, [:directory] => :environment do |_t, args|
    directory = args[:directory]

    if directory.blank?
      puts "Usage: bundle exec rails \"counter_summary:import[/path/to/csv/files]\""
      puts "Example: bundle exec rails \"counter_summary:import[/tmp/siq_stats]\""
      exit 1
    end

    unless Dir.exist?(directory)
      puts "Error: Directory not found: #{directory}"
      exit 1
    end

    # Find all CSV files matching the pattern
    files = Dir.glob(File.join(directory, 'fulcrum_metric_totals-*.csv')).sort

    if files.empty?
      puts "No CSV files found matching pattern: fulcrum_metric_totals-*.csv"
      exit 1
    end

    puts "Found #{files.length} CSV files to process"
    puts "=" * 80

    success_count = 0
    skip_count = 0
    error_count = 0
    errors = []

    files.each do |file_path|
      filename = File.basename(file_path)

      # Extract year and month from filename: fulcrum_metric_totals-2024-07.csv
      match = filename.match(/fulcrum_metric_totals-(\d{4})-(\d{2})\.csv/)

      unless match
        puts "SKIP: Skipping #{filename} - doesn't match expected pattern"
        skip_count += 1
        next
      end

      year = match[1].to_i
      month = match[2].to_i

      # Check if we already have stats for this period
      if CounterSummary.exists_for_period?(year, month)
        puts "SKIP: #{filename} - Already exists (#{year}-#{format('%02d', month)})"
        skip_count += 1
        next
      end

      print "Processing #{filename} (#{year}-#{format('%02d', month)})... "

      begin
        # Use the CSV processor to parse and roll up metrics
        processor = CounterSummaryService::CsvProcessor.new(year, month)
        monograph_stats = processor.process_file(file_path)

        if processor.errors.any?
          puts "\n   WARN: Warnings during processing:"
          processor.errors.first(50).each do |error|
            puts "      - #{error}"
          end
          if processor.errors.length > 50
            puts "      ... and #{processor.errors.length - 50} more warnings"
          end
        end

        # Save statistics
        saved = 0
        monograph_stats.each do |stat_data|
          CounterSummary.create!(stat_data)
          saved += 1
        rescue ActiveRecord::RecordInvalid => e
          errors << "#{filename}: Failed to save #{stat_data[:monograph_noid]} - #{e.message}"
        end

        puts "OK: Saved #{saved} monographs"
        success_count += 1

      rescue StandardError => e
        puts "ERROR: #{e.message}"
        errors << "#{filename}: #{e.message}"
        error_count += 1
      end
    end

    puts "=" * 80
    puts "\nImport Summary:"
    puts "  OK: Successfully processed: #{success_count} files"
    puts "  SKIP: Skipped: #{skip_count} files"
    puts "  ERROR: Errors: #{error_count} files"
    puts "\nTotal monograph statistics: #{CounterSummary.count}"

    if errors.any?
      puts "\nWARN: Errors encountered:"
      errors.each { |error| puts "  - #{error}" }
    end
  end

  desc 'Delete all counter statistics (WARNING: destructive)'
  task clear: :environment do
    print "Are you sure you want to delete ALL counter statistics? Type 'yes' to confirm: "
    confirmation = $stdin.gets&.chomp

    if confirmation == 'yes'
      count = CounterSummary.count
      CounterSummary.delete_all
      puts "OK: Deleted #{count} counter statistics records"
    else
      puts "CANCELLED: Operation cancelled"
    end
  end

  desc 'Show counter statistics summary'
  task summary: :environment do
    total = CounterSummary.count

    if total.zero?
      puts "No counter statistics found in database"
      exit 0
    end

    puts "Counter Statistics Summary"
    puts "=" * 80
    puts "Total records: #{total}"
    puts "\nMonographs with statistics: #{CounterSummary.distinct.count(:monograph_noid)}"

    # Group by period
    puts "\nStatistics by period:"
    stats_by_period = CounterSummary.group(:year, :month).count
    stats_by_period.sort.each do |(year, month), count|
      month_name = Date::MONTHNAMES[month]
      puts "  #{month_name} #{year}: #{count} monographs"
    end

    # Date range
    oldest = CounterSummary.order(year: :asc, month: :asc).first
    newest = CounterSummary.order(year: :desc, month: :desc).first

    if oldest && newest
      puts "\nDate range:"
      puts "  Oldest: #{Date::MONTHNAMES[oldest.month]} #{oldest.year}"
      puts "  Newest: #{Date::MONTHNAMES[newest.month]} #{newest.year}"
    end
  end
end
# rubocop:enable Metrics/BlockLength
