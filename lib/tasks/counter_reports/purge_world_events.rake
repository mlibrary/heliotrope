# frozen_string_literal: true

# This is a one off for FOPS-1244
# We no longer want to track World (institution 0) Investigation-only and Search records
# and we're going to purge them from the database to save space.

namespace :heliotrope do # rubocop:disable Metrics/BlockLength
  desc "Purge institution 0 Investigation-only and Search records (dry run by default)"
  task :purge_world_counter_events, [:batch_size, :pause_seconds, :start_id, :delete] => :environment do |_task, args| # rubocop:disable Metrics/BlockLength
    # Preview: bundle exec rails heliotrope:purge_world_counter_events
    # Delete:  bundle exec rails 'heliotrope:purge_world_counter_events[500,0.1,0,true]'
    # Resume by replacing start_id with the last reported through_id.
    args.with_defaults(batch_size: "500", pause_seconds: "0.1", start_id: "0", delete: "false")
    batch_size = Integer(args.batch_size, 10)
    pause_seconds = Float(args.pause_seconds)
    cursor = Integer(args.start_id, 10)
    raise ArgumentError, "batch_size must be between 1 and 1000" unless (1..1000).cover?(batch_size)
    raise ArgumentError, "pause_seconds must be finite and at least 0.1" unless pause_seconds.finite? && pause_seconds >= 0.1
    raise ArgumentError, "start_id must be nonnegative" if cursor.negative?
    raise ArgumentError, "delete must be true or false" unless %w[true false].include?(args.delete)

    engine = CounterReport.connection.select_value("SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'counter_reports'")
    raise "counter_reports must use InnoDB to avoid table-level write locks" unless engine == "InnoDB"

    deleting = args.delete == "true"
    upper_id = CounterReport.maximum(:id) || cursor
    world = CounterReport.where(institution: 0)
    targets = world.where(investigation: 1, request: nil).or(world.where(search: 1))
    scanned = 0
    total = 0
    puts "#{deleting ? 'DELETE' : 'DRY RUN'} institution 0 events: start_id=#{cursor}, maximum_id=#{upper_id}, batch_size=#{batch_size}, pause_seconds=#{pause_seconds}"

    loop do
      # Walk the primary key, not the filtered relation: sparse matches must not
      # cause repeated scans of the institution index. Never instantiate records.
      ids = CounterReport.where("id > ? AND id <= ?", cursor, upper_id).order(:id).limit(batch_size).pluck(:id)
      break if ids.empty?

      batch = targets.where(id: ids)
      # Each delete is a separate, bounded statement; do not wrap this loop in a transaction.
      affected = deleting ? batch.delete_all : batch.count
      cursor = ids.last
      scanned += ids.length
      total += affected
      puts "through_id=#{cursor} scanned=#{scanned} #{deleting ? 'deleted' : 'matched'}=#{total} batch_matches=#{affected}"
      $stdout.flush
      Kernel.sleep(pause_seconds)
    end

    puts "Finished #{deleting ? 'deleting' : 'dry run'}: scanned=#{scanned}, #{deleting ? 'deleted' : 'matched'}=#{total}, through_id=#{cursor}, maximum_id=#{upper_id}"
  end
end
