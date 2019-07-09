# frozen_string_literal: true

desc 'Update APTrust Deposits'
namespace :heliotrope do
  task aptrust: :environment do
    AptrustJob.perform_later
    p "APTrustJob.perform_later"
  end
end
