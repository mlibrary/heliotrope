desc 'Clean the IIIF cache and the uploads directory'
namespace :heliotrope do
  task clean_cache: :environment do
    # This task should be run nightly from a Cron

    # 1. IIIF tile images are stored in the Rails.cache
    #    Expiration is set in config/initializers/riiif_initializer.rb
    #    This command cleans up everything in the cache that's been expired
    Rails.cache.cleanup
    Rails.logger.info("clean_cache cleaned up cache")

    # 2. IIIF stores it's "base" images in tmp/network_files
    #    These should be periodically cleaned up as well
    network_files_path = Rails.root.join('tmp', 'network_files')

    Dir.foreach(network_files_path) do |f|

      file = "#{network_files_path}/#{f}"

      if File.mtime(file) < 7.days.ago && File.file?(file)
        Rails.logger.info("clean_cache deleted: #{file}")
        File.delete(file)
      end
    end

    # 3. tmp/uploads  should be cleaned out as well since we don't
    #    need these files after they've been processed
    uploads_path = Rails.root.join('tmp', 'uploads')

    Dir.glob("#{uploads_path}/*") do |dir|
      Rails.logger.info("clean_cache deleted: #{dir}")
      FileUtils.remove_entry_secure(dir)
    end
  end
end
