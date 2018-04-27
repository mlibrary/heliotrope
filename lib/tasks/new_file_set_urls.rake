# frozen_string_literal: true

desc 'output handle-suitable URLs for recently-uploaded FileSets'
namespace :heliotrope do
  task :new_file_set_urls, [:date] => :environment do |_t, args|
    # Usage: Needs a valid date as a parameter, many formats should work, e.g.:
    # $ bundle exec rake "heliotrope:new_file_set_urls[1 Apr 2018 00:00:00 +0000]"

    # Right now we're using this to generate handles outside of heliotrope

    cutoff_time = DateTime.parse(args.date)

    FileSet.all.to_a.each do |f|
      next if f.parent.blank? || f.date_uploaded < cutoff_time
      # in the long run I think all EPUB handles should point to the epub_path (CSB viewer), but right now that...
      # only works for the monograph's representative EPUB (https://github.com/mlibrary/heliotrope/issues/1702)
      featured_representative = FeaturedRepresentative.where(monograph_id: f.parent.id, file_set_id: f.id).first
      if featured_representative&.kind == 'epub'
        puts "#{f.id},#{Rails.application.routes.url_helpers.epub_path(f.id)}"
      else
        puts "#{f.id},#{Rails.application.routes.url_helpers.hyrax_file_set_path(f.id)}"
      end
    end
  end
end
