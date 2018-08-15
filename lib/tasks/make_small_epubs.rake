# frozen_string_literal: true

desc 'Create "minimal" packed epubs from fixed-layout epubs'
namespace :heliotrope do
  task make_small_epubs: :environment do
    FeaturedRepresentative.where(kind: 'epub').each do |epub|
      MinimalEpubJob.perform_later(UnpackService.root_path_from_noid(epub.file_set_id, 'epub'))
    end
  end
end
