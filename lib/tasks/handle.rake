# frozen_string_literal: true

desc 'Update Handle Records'
namespace :heliotrope do
  task handle: :environment do
    HandleJob.perform_later
  end
end
