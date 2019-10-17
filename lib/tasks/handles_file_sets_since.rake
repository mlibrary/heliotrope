# frozen_string_literal: true

desc 'output handle-suitable URLs for recently-uploaded FileSets'
namespace :heliotrope do
  task :handles_file_sets_since, [:datetime] => :environment do |_t, args|
    # Usage: Needs a valid date as a parameter, many formats should work, e.g.:
    # $ bundle exec rake "heliotrope:handles_file_sets_since[2018-06-08T00:00:00-05:00]"

    # Right now we're using this to generate handles outside of heliotrope

    cutoff_time = DateTime.strptime(args.datetime, '%Y-%m-%dT%H:%M:%S%z')

    FileSet.all.each do |f|
      next if f.parent.blank? || f.date_uploaded < cutoff_time
      puts "#{f.id},#{Rails.application.routes.url_helpers.hyrax_file_set_path(f.id)}"
    end
  end
end
