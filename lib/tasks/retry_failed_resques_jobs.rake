# frozen_string_literal: true

# See HELIO-4251
# We get resque job failures for IRUS counter submissions due to network errors
# These jobs can be re-run
# This is to be run nightly via cron to retry the failures
# While currently just for IRUS failures, other kinds of jobs that failed for 
# temporary reasons could possibly be added to this.

desc 'retry (some) failed resque jobs'
namespace :heliotrope do
  task retry_failed_resque_jobs: :environment do
    (Resque::Failure.count-1).downto(0).each do |error_index_number|
      failure = Resque::Failure.all(error_index_number)

      if (failure["exception"] == "Net::OpenTimeout" && failure["error"] == "execution expired") ||
         (failure["exception"] == "Net::OpenTimeout" && failure["error"] == "Net::OpenTimeout") ||
         (failure["exception"] == "Net::ReadTimeout" && failure["error"] == "Net::ReadTimeout")
        
        Rails.logger.info("RESQUE RETRY with #{failure['payload']}")
        Resque::Failure.requeue(error_index_number)
        Resque::Failure.remove(error_index_number)
      end
    end
  end
end