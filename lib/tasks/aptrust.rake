# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Update APTrust Deposits'
namespace :heliotrope do
  task aptrust: :environment do
    AptrustJob.perform_later
    p "APTrustJob.perform_later"
  end
end
