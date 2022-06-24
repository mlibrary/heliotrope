# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Update Handle Records'
namespace :heliotrope do
  task handle: :environment do
    HandleJob.perform_later
    p "HandleJob.perform_later"
  end
end
