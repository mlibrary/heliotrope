# frozen_string_literal: true

desc 'Unpack EPUB and WEBGL assets'
namespace :heliotrope do
  task unpack_assets: :environment do
    FeaturedRepresentative.where(kind: 'epub').or(FeaturedRepresentative.where(kind: 'webgl')).each do |fr|
      puts "Unpacking #{fr.kind} #{fr.file_set_id}"
      UnpackJob.perform_later(fr.file_set_id, fr.kind)
    end
  end
end
