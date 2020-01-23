# frozen_string_literal: true

desc 'output handle-suitable URLs for a monograph'
namespace :heliotrope do
  task :handles_single_monograph, [:monograph_id] => :environment do |_t, args|
    # Usage: Needs a valid monograph id as a parameter
    # $ bundle exec rake "heliotrope:handles_single_monograph[q811kk573]"

    # Right now we're using this to generate handles outside of heliotrope

    m = Monograph.find(args.monograph_id)
    puts "#{m.id},#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)}"

    m.ordered_members.to_a.each do |f|
      next unless f.file_set?
      puts "#{f.id},#{Rails.application.routes.url_helpers.hyrax_file_set_path(f.id)}"
    end
  end
end
