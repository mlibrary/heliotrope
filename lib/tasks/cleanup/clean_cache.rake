# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Clean the IIIF cache and the uploads directory'
namespace :heliotrope do
  task clean_cache: :environment do
    # This task should be run nightly from a Cron

    # 1. IIIF tile images are stored in the Rails.cache
    #    Expiration is set in config/initializers/riiif_initializer.rb
    #    This command cleans up everything in the cache that's been expired
    # Rails.cache.cleanup
    # It turns out that "Rails.cache.cleanup" is broken. It's fixed in rails 5.2,
    # but for now we'll need to delete expired cached items. https://github.com/rails/rails/pull/30789
    # UPDATE:
    # It seems that "Rails.cache.cleanup" still has a problem in Rails 5.2.4.6
    # see HELIO-2302 for details. The error is:
    #
    # NoMethodError: undefined method `expired?' for #<String:0x0000563530e954b0>
    # apps/heliotrope/lib/tasks/cleanup/clean_cache.rake:11:in `block (2 levels) in <top (required)>'
    #
    # I don't know. Maybe we're doing something wrong...
    # But I've been poking around and testing, and the work-around code below seems to be working fine.
    # It goes through the cache, gets each cache key and does a read. If that cached object is expired,
    # it deletes it. So I guess that's fine.
    #
    # HELIO-3558: it's really slow though, so only check the "old" caches
    #
    # Also, I'm starting to suspect that using the "low level" cache in this way is usually related to
    # a model in rails. Or some object that should respond to "expired?" anyway.... Which we're not doing.
    # We might be using this in a way that isn't supported by Rails.cache.cleanup.
    Dir.glob(Rails.root.join("tmp", "cache", "[A-Z0-9][A-Z0-9][A-Z0-9]", "[A-Z0-9][A-Z0-9][A-Z0-9]", "*")).each do |path|
      # Test the file via "read", which will likely delete it, if it's timestamp is 30 days or older
      if File.exist?(path) && 30.days.ago >= File.mtime(path)
        Rails.cache.read(CGI.unescape(File.basename(path)))
      end
    end
    Rails.logger.info("clean_cache cleaned up cache")


    # 2. IIIF stores it's "base" images in tmp/network_files
    #    These should be periodically cleaned up as well
    network_files_path = Rails.root.join('tmp', 'network_files')

    Dir.foreach(network_files_path) do |f|
      file = "#{network_files_path}/#{f}"

      # We track modified dates of these, so new images are cached if the modifed date changes.
      # So there's no real reason to delete them. But I don't know. I guess do it monthly to
      # match https://github.com/mlibrary/heliotrope/blob/master/config/initializers/riiif_initializer.rb#L31
      # I'm not really sure this is neccessary...
      if File.mtime(file) < 30.days.ago && File.file?(file)
        Rails.logger.info("clean_cache deleted: #{file}")
        File.delete(file)
      end
    end

    # 3. tmp/uploads  should be cleaned out as well since we don't
    #    need these files after they've been processed
    uploads_path = Rails.root.join('tmp', 'uploads')

    Dir.glob("#{uploads_path}/*") do |dir|
      if Dir.exist?(dir) && 7.days.ago >= File.mtime(dir)
        Rails.logger.info("clean_cache deleted: #{dir}")
        FileUtils.remove_entry_secure(dir)
      end
    end
  end
end
