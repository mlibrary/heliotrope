# frozen_string_literal: true

CarrierWave.configure do |config|
  if Rails.env.test? || Rails.env.cucumber?
    # store test uploads and cache in the spec dir which gets deleted afterwards
    config.root = Rails.root.join('spec', 'support', 'uploads')
    config.cache_dir = Rails.root.join('spec', 'support', 'uploads', 'tmp')
    config.storage = :file
    config.enable_processing = false
  else
    # uploads end up alongside original 'beta' press logos
    config.root = Rails.root.join('app', 'assets', 'images')
    # store user uploads cache in the app tmp directory
    config.cache_dir = Rails.root.join('tmp', 'uploads')
  end
end
