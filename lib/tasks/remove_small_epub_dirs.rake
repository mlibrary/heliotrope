# frozen_string_literal: true

desc 'Removes all the ".sm" working dirs made by heliotrope:make_small_epubs'
namespace :heliotrope do
  task remove_small_epub_dirs: :environment do
    FeaturedRepresentative.where(kind: 'epub').each do |fr|
      epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(fr.file_set_id, 'epub'))
      next unless epub.multi_rendition?

      sm = File.join(epub.root_path, epub.id + ".sm")
      FileUtils.remove_entry_secure sm if Dir.exist? sm
      p "removed #{sm}" unless Dir.exist? sm
    end
  end
end
