# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

namespace :heliotrope do
  desc 'Smart restart: only restart resque workers if all idle'
  task :smart_resque_restart, [:log_dir] => :environment do |_t, args|
    unless args[:log_dir] && File.writable?(args[:log_dir])
      abort 'ERROR: log_dir parameter is required and must be writable. Usage: rake heliotrope:smart_resque_restart[/path/to/log/dir]'
    end

    log_dir = args[:log_dir]
    log_file = File.join(log_dir, 'resque_restart.log')

    # Helper to append to log
    log_message = ->(message) do
      File.open(log_file, 'a') do |f|
        f.puts message
      end
    end

    log_message.call('=' * 40)
    log_message.call("#{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')} - Daily Check")

    # Get current memory state for idle workers (for logging only)
    idle_workers = `ps aux | grep -E 'resque-[0-9.]+:' | grep 'Waiting for' | grep -v grep`.lines

    if idle_workers.any?
      total_mem = 0
      idle_workers.each do |line|
        # RSS is the 6th column (0-indexed = 5)
        mem = line.split[5].to_i
        total_mem += mem
      end

      count = idle_workers.count
      avg_mb = total_mem.to_f / count / 1024.0
      total_mb = total_mem.to_f / 1024.0

      log_message.call("  Idle workers: #{count}, Avg: #{avg_mb.round(1)} MB, Total: #{total_mb.round(1)} MB")
    else
      log_message.call('  No idle workers found')
    end

    # Check for active jobs using Resque state rather than parsing process titles
    active_worker_count = Resque.workers.count(&:working?)

    if active_worker_count.positive?
      log_message.call('  Status: SKIPPED - Active jobs detected')
      log_message.call("  Active job count: #{active_worker_count}")
      exit 0
    end

    # All workers idle, safe to restart
    log_message.call('  Status: RESTARTING - All workers idle')

    result = system('sudo -n systemctl restart fulcrum-resque.service')
    exit_status = $?.exitstatus

    if result
      log_message.call('  Result: SUCCESS')

      # Wait for workers to fully start
      sleep 5

      # Log new baseline
      new_workers = `ps aux | grep -E 'resque-[0-9.]+:' | grep 'Waiting for' | grep -v grep`.lines

      if new_workers.any?
        total_mem = 0
        new_workers.each do |line|
          mem = line.split[5].to_i
          total_mem += mem
        end

        count = new_workers.count
        avg_mb = total_mem.to_f / count / 1024.0

        log_message.call("  New baseline: #{avg_mb.round(1)} MB avg across #{count} workers")
      end
    else
      log_message.call("  Result: FAILED (exit status: #{exit_status})")
      exit 1
    end
  end
end
