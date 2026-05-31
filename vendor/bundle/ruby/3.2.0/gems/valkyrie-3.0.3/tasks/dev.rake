# frozen_string_literal: true

namespace :server do
  desc "Start solr and fedora servers for testing"
  task :start do
    require 'rails'
    `lando start`
    `bundle exec rake db:create`
    `bundle exec rake db:migrate`
    puts "Started Solr/Fedora/Postgres"
  end

  desc "Cleanup test servers"
  task :clean do
    require 'rails'
    `lando destroy -y`
    `lando start`
    `bundle exec rake db:create`
    `bundle exec rake db:migrate`
    puts "Cleaned/Started Solr/Fedora/Postgres"
  end

  desc "Stop test servers"
  task :stop do
    `lando stop -y`
  end
end
