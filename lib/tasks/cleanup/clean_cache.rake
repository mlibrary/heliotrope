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
    Dir.glob(File.join(Rails.cache.cache_path, "[A-Z0-9][A-Z0-9][A-Z0-9]", "[A-Z0-9][A-Z0-9][A-Z0-9]", "*")).each do |path|
    # Dir.glob(Rails.root.join("tmp", "cache", "[A-Z0-9][A-Z0-9][A-Z0-9]", "[A-Z0-9][A-Z0-9][A-Z0-9]", "*")).each do |path|
      # Test the file via "read", which will likely delete it, if it's timestamp is 30 days or older
      if File.exist?(path) && 30.days.ago >= File.mtime(path)
        Rails.logger.info("clean_cache deleted: #{path}")
        Rails.cache.read(CGI.unescape(File.basename(path)))
      end
    end


    # 2. IIIF stores its "base"/full images in Settings.riiif_network_files_path (HELIO-4470)
    #    See HELIO-4398. Only files that are no longer in Solr, for whatever reason, will be deleted.
    network_files_path = Settings.riiif_network_files_path

    image_urls = []

    # Grab all FileSet docs and then whittle them down in to image formats while grabbing the `original_file_id_ssi`...
    # value (Fedora path) that will allow us to figure out what the equivalent RIIIF cached file name would be.
    #
    # Note that using an all-in-one Solr query to search for FileSets with image file extensions is not reliable, I...
    # guess due to stemming/tokenization. Filenames containing underscores are among those not returned by such a query.
    # Only about half of expected images are returned. Hence the `any?` in the loop instead.
    docs = ActiveFedora::SolrService.query('+has_model_ssim:FileSet', fl: ['file_size_lts', 'label_tesim', 'original_file_id_ssi'], rows: 100000)
    docs.each do |doc|
      image_urls << doc['original_file_id_ssi'] if doc['original_file_id_ssi'].present? &&
        %w[.bmp .gif .jp2 .jpeg .jpg .png .tif .tiff].any? { |image_extension| doc['label_tesim']&.first&.strip&.end_with? image_extension }
    end
    image_urls.uniq!

    # Convert to full Fedora path and MD5 value used for the cached files' names.
    riiif_cached_file_names = image_urls.map { |url| Digest::MD5.hexdigest(ActiveFedora::Base.id_to_uri(CGI.unescape(url))) }.uniq

    Dir.foreach(network_files_path) do |f|
      file = "#{network_files_path}/#{f}"

      # Anything that has been seen in Solr in the past 30 days is kept. This also makes it safe for network...
      # glitches, Solr outages, reindexing the core etc. Only image files that have been deleted from the system...
      # will be removed here. This will eventually take our disk space usage up to over 100GB, but right now we're...
      # using 38GB and still getting occasional Puma overload from not caching enough, so it's a price worth paying.
      # aside: when a new version of an image is uploaded we delete the RIIIF base image in CharacterizeJob.
      if riiif_cached_file_names.include? f
        FileUtils.touch(file)
      elsif File.atime(file) < 30.days.ago && File.file?(file)
        Rails.logger.info("clean_cache deleted: #{file}")
        File.delete(file)
      end
    end

    # 3. tmp/uploads  should be cleaned out as well since we don't
    #    need these files after they've been processed
    # uploads_path = File.join(Settings.scratch_space_path, 'uploads')
    Dir.glob("#{Settings.uploads_path}/*") do |dir|
      if Dir.exist?(dir) && 7.days.ago >= File.mtime(dir)
        Rails.logger.info("clean_cache deleted: #{dir}")
        FileUtils.remove_entry_secure(dir)
      end
    end

    # 4. We've started putting temp files in a "scratch" dir and now it's full of old files from ingest
    # or maybe pdf or apache tika processing. Lots of files that look like:
    #
    # -rw------- 1 2600062 1001460   42M Feb 13 19:46 5425kd82720250213-1519359-hxpnve
    # -rw------- 1 2600062 1001460   13M Feb 13 19:46 fj236582q20250213-1519348-1a31izh
    # -rw------- 1 2600062 1001460     0 Feb 13 19:46 6q182p56620250213-2118841-135env7
    # -rw------- 1 2600062 1001460   39M Feb 13 19:46 df65vc29520250213-2118822-z3lvh0
    # -rw------- 1 2600062 1001460  121M Feb 13 19:46 0z709084720250213-2118805-1k7hc7e 
    #
    # We don't need these. Should be safe to delete them if they're older than a day
    # Dir.glob(File.join(Settings.scratch_space_path, "*")).each do |path|
    #   if File.basename(path).match?(/^\w{17}\-\d{7}\-\w{6}$/)
    #     # Yesterday is less than today. Last week is less than yesterday.
    #     if File.mtime(path) < 1.day.ago
    #       Rails.logger.info("clean_cache deleted: #{path}")
    #       FileUtils.remove_entry_secure(path)
    #     end
    #   end
    # end

    # UPDATE see HELIO-4833
    # It turns out we have a cron in production the deletes from scratch every night. I've decided to just add that to
    # staging as well. Preview doesn't need it since it's scratch space in in "app tmp" so gets rolled out with each new deploy.
    # I'll leave the above code commented out. We could do something with it in the future if we want to.

  end
end
