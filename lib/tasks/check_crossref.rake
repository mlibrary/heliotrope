# frozen_string_literal: true

desc 'Check Crossref for DOI submissions that are pending'
namespace :heliotrope do
  task check_crossref: :environment do
    # If nothing in the CrossrefSubmissionLog has a status of "submitted",
    # crossref will not be polled. So it's fine to call this task from a
    # cron fairly frequently if needed.
    CrossrefPollJob.perform_later
  end
end
