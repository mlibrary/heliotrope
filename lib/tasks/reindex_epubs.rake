# frozen_string_literal: true

desc 'Reindex All Epubs'
namespace :heliotrope do
  task reindex_epubs: :environment do
    FeaturedRepresentative.where(kind: 'epub').each do |epub|
      ReindexEpubJob.perform_later(epub.file_set_id)
    end
    p "Reindexing #{FeaturedRepresentative.where(kind: 'epub').count} epubs"
  end
end
