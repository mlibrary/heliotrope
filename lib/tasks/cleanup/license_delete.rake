# frozen_string_literal: true

desc 'Cleanup :none licenses'
namespace :heliotrope do
  task license_delete: :environment do
    LicenseDeleteJob.perform_later
    p "LicenseDeleteJob.perform_later"
  end
end
