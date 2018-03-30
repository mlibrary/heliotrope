# frozen_string_literal: true

desc 'output handle-suitable URLs for a monograph'
namespace :heliotrope do
  task :monograph_urls, [:monograph_id] => :environment do |_t, args|
    # Usage: Needs a valid monograph id as a parameter
    # $ bundle exec rake "heliotrope:file_set_urls[q811kk573]"

    # Right now we're using this to generate handles outside of heliotrope

    m = Monograph.find(args.monograph_id)

    puts "\"#{Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)}\",\"#{m.title.first}\""
    m.ordered_members.to_a.each do |member|
      next unless member.file_set?
      # in the long run I think all EPUB handles should point to the epub_path (CSB viewer), but right now that...
      # only works for the monograph's representative EPUB (https://github.com/mlibrary/heliotrope/issues/1702)
      featured_representative = FeaturedRepresentative.where(monograph_id: m.id, file_set_id: member.id).first
      if featured_representative&.kind == 'epub'
        puts "\"#{Rails.application.routes.url_helpers.epub_path(member.id)}\",\"#{member.label}\""
      else
        puts "\"#{Rails.application.routes.url_helpers.hyrax_file_set_path(member.id)}\",\"#{member.label}\""
      end
    end
  end
end
