# frozen_string_literal: true

Hyrax.config do |config|
  # We're need to use the Clamby gem instead of ClamAV gem as the latter no longer builds:https://github.com/eagleas/clamav/issues/11
  # https://github.com/eagleas/clamav/issues/11
  # I think probably Hyrax will swtich to clamby in version 4.0 but I'm not clear on it.
  # See https://github.com/samvera/hydra-works/blob/master/lib/hydra/works/virus_scanner.rb and HELIO-3230
  config.virus_scanner = Hydra::Works::VirusScanner

  # Injected via `rails g curation_concerns:work Monograph`
  config.register_curation_concern :monograph
  # Should schema.org microdata be displayed?
  # config.display_microdata = true

  # What default microdata type should be used if a more appropriate
  # type can not be found in the locale file?
  # config.microdata_default_type = 'http://schema.org/CreativeWork'

  # How frequently should a file be audited.
  # Note: In Hyrax you must trigger the FileSetAuditService manually.
  # config.max_days_between_audits = 7

  # Enable displaying usage statistics in the UI
  # Requires a Google Analytics id and OAuth2 keyfile.  See README for more info
  # config.analytics = false

  # Specify a Google Analytics tracking ID to gather usage statistics. NB: this is left here for posterity only...
  # as heliotrope pulls the GA tracking ID from Rails.application.secrets.google_analytics_id
  # config.google_analytics_id = 'UA-99999999-1'

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # config.analytic_start_date = DateTime.new(2014,9,10)

  # Where to store tempfiles, leave blank for the system temp directory (e.g. /tmp)
  # config.temp_file_base = '/home/developer1'

  # Location on local file system where derivatives will be stored.
  # If you use a multi-server architecture, this MUST be a shared volume.
  config.derivatives_path = Settings.derivatives_path

  # Location on local file system where uploaded files will be staged
  # prior to being ingested into the repository or having derivatives generated.
  # If you use a multi-server architecture, this MUST be a shared volume.
  config.working_path = Settings.uploads_path

  # If you have ffmpeg installed and want to transcode audio and video uncomment this line
  config.enable_ffmpeg = true

  # Hyrax uses NOIDs for files and collections instead of Fedora UUIDs
  # where NOID = 10-character string and UUID = 32-character string w/ hyphens
  # config.enable_noids = true

  # Specify a different template for your repository's NOID IDs
  # config.noid_template = ".reeddeeddk"

  # Store identifier minter's state in a file for later replayability
  # If you use a multi-server architecture, this MUST be on a shared volume.
  config.minter_statefile = Settings.minter_path

  # Specify the prefix for Redis keys:
  # config.redis_namespace = "curation_concerns"

  # Specify the path to the file characterization tool:
  # config.fits_path = "fits.sh"

  # Specify a date you wish to start collecting Google Analytic statistics for.
  # Leaving it blank will set the start date to when ever the file was uploaded by
  # NOTE: if you have always sent analytics to GA for downloads and page views leave this commented out
  # config.analytic_start_date = DateTime.new(2014,9,10)

  config.ingest_queue_name = :ingest

  # For now turn off user notifications. When we decide about how to do things like
  # workflows we can turn them back on.
  config.realtime_notifications = false

  # we're setting these with a method overwrite in models/concerns/heliotrope_hyrax_user_behavior.rb
  # https://tools.lib.umich.edu/jira/browse/HELIO-2065
  config.audit_user_key = 'fulcrum-system'
  config.batch_user_key = 'fulcrum-system'

  # Options to control the file uploader
  config.uploader = {
    limitConcurrentUploads: 6,
    maxNumberOfFiles: 600,
    maxFileSize: 5.gigabytes
  }

  # https://tools.lib.umich.edu/jira/browse/HELIO-2688
  config.work_requires_files = false
end

Date::DATE_FORMATS[:standard] = '%m/%d/%Y'
