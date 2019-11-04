# frozen_string_literal: true

desc 'Cleanup Small EPUBs (remove "<noid>.sm.epub" file and "<noid>.sm" directory from EPUB derivatives)'
namespace :heliotrope do
  task cleanup_small_epubs: :environment do
    CleanupSmallEpubsJob.perform_later
    p "CleanupSmallEpubsJob.perform_later"
  end
end
