desc 'get file_set urls and file_set labels for a monograph'
namespace :heliotrope do
  task :file_set_urls, [:monograph_id] => :environment do |t, args|

    # Usage: Needs a valid monograph id as a parameter
    # $ bundle exec rake "heliotrope:file_set_urls[q811kk573]"

    # Right now we're using this to generate handles outside of heliotrope

    m = Monograph.find(args.monograph_id)

    m.ordered_members.to_a.each do |member|
      if member.file_set?
        puts "\"#{Rails.application.routes.url_helpers.curation_concerns_file_set_path(member.id)}\",\"#{member.label}\""
      end
    end
  end
end
