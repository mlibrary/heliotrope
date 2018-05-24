# frozen_string_literal: true

CarrierWave.configure do |config|
  if Rails.env.test? || Rails.env.cucumber?
    # store test uploads and cache in the tmp dir which gets deleted afterwards
    config.root = Rails.root.join('tmp', 'spec', 'uploads')
    config.cache_dir = Rails.root.join('tmp', 'spec', 'uploads', 'cache')
    config.storage = :file
    config.enable_processing = false
  end
end
