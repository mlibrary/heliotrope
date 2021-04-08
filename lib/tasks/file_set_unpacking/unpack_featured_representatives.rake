# frozen_string_literal: true

desc 'Loop over all FeaturedRepresentatives of a given kind and (re)unpack them'
namespace :heliotrope do
  task :unpack_featured_representatives, [:kind] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:unpack_featured_representatives[pdf_ebook]"

    FeaturedRepresentative.where(kind: args.kind).each do |fr|
      begin
        f = FileSet.find(fr.file_set_id)
        next unless f.present?

        UnpackJob.perform_later(f.id, args.kind)
        puts "Unpacking FeaturedRepresentative of kind '#{args.kind}' and NOID #{f.id}"
      rescue Ldp::Gone # should be unlikely but I've seen this on preview
        next
      end
    end
  end
end
