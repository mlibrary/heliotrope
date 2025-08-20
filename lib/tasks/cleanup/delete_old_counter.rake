# frozen_string_literal: true

#########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# HELIO-4957 too many AI bots on preview make this table unecessarily large
desc 'Removes CounteReport records on preview only'
namespace :heliotrope do
  if Settings.host == "heliotrope-preview.hydra.lib.umich.edu"
    task delete_old_counter: :environment do
      # This task is intended to clean up old CounterReport records on the preview environment.
      # It will not run in production or development environments.
      CounterReport.where('created_at < ?', 1.week.ago).delete_all
      puts "Old CounterReport records deleted from preview environment."
    end
  else
    task delete_old_counter: :environment do
      puts "This task is only for the preview environment and will not run here."
    end
  end
end
