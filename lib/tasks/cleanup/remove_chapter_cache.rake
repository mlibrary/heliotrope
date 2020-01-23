# frozen_string_literal: true

desc 'Removes all cached epub chapters regardless of expiration'
namespace :heliotrope do
  task remove_chapter_cache: :environment do
    # Cached pdf epub chapters have a 30 day expiration so will automatically be
    # removed by the cron that runs rake heliotrope:clean_cache.
    # This is for removing all cached epub pdf chapters before the expiration.
    # This will only work in production environments, not development.
    # If you're caching in dev it's probably in-memory so just restart the rails server
    Rails.cache.delete_matched(/^pdf:.*/)
  end
end
