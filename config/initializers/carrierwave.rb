# frozen_string_literal: true

CarrierWave.configure do |config|
  if Rails.env.test? || Rails.env.cucumber?
    # store test uploads and cache in the tmp dir which gets deleted afterwards
    config.root = File.join(Settings.scratch_space_path, 'spec', 'uploads')
    config.cache_dir = File.join(Settings.scratch_space_path, 'spec', 'uploads', 'cache')
    config.storage = :file
    config.enable_processing = false
  end
end
