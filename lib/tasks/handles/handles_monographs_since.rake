# frozen_string_literal: true

desc 'output handle-suitable URLs for recently-uploaded Monographs and their FileSets'
namespace :heliotrope do
  task :handles_monographs_since, [:datetime] => :environment do |_t, args|
    # Usage: Needs a valid date as a parameter, many formats should work, e.g.:
    # $ bundle exec rake "heliotrope:handles_monographs_since[2018-06-08T00:00:00-05:00]"

    # Right now we're using this to generate handles outside of heliotrope

    cutoff_time = DateTime.strptime(args.datetime, '%Y-%m-%dT%H:%M:%S%z')

    Monograph.all.each do |m|
      next if m.date_uploaded < cutoff_time
      puts "#{m.id},#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)}"

      m.ordered_members.to_a.each do |f|
        puts "#{f.id},#{Rails.application.routes.url_helpers.hyrax_file_set_path(f.id)}"
      end
    end
  end
end
