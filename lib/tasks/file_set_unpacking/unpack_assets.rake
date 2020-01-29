# frozen_string_literal: true

desc 'Unpack EPUB and WEBGL assets (initial migration to unpacked from cached, see #1692)'
namespace :heliotrope do
  task unpack_assets: :environment do
    FeaturedRepresentative.where(kind: 'epub').or(FeaturedRepresentative.where(kind: 'webgl')).each do |fr|
      puts "Unpacking #{fr.kind} #{fr.file_set_id}"
      UnpackJob.perform_later(fr.file_set_id, fr.kind)
    end
  end

  task remove_unpacked_assets: :environment do
    # This is just for testing and will be removed later
    FeaturedRepresentative.where(kind: 'epub').or(FeaturedRepresentative.where(kind: 'webgl')).each do |fr|
      root_path = UnpackService.root_path_from_noid(fr.file_set_id, fr.kind)
      if Dir.exist? root_path
        puts "Removing #{root_path}"
        FileUtils.remove_entry_secure(root_path)
      end
    end
  end
end
