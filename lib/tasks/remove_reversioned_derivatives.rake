# frozen_string_literal: true

desc 'Removes old/reversioned epub or webgl derivatives'
namespace :heliotrope do
  task remove_reversioned_derivatives: :environment do
    ['epub', 'webgl'].each do |kind|
      FeaturedRepresentative.where(kind: kind).each do |fr|
        root_path = UnpackService.root_path_from_noid(fr.file_set_id, kind)
        removes = root_path.sub(/\/*.\-#{kind}$/, '/') + "TO-BE-REMOVED-"
        Dir.glob("#{removes}*") do |dir|
          begin
            FileUtils.remove_entry_secure dir
          rescue SystemCallError => e
            # This is fine. When called from a nightly cron we can try again later.
            p e.message
          end
        end
      end
    end
  end
end
