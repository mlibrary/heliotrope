# frozen_string_literal: true

class ManifestUploader < CarrierWave::Uploader::Base
  storage :file

  def store_dir
    Rails.root.join("tmp", "uploads", model.class.to_s.underscore, model.id)
  end

  def cache_dir
    Rails.root.join("tmp", "uploads", "cache", model.class.to_s.underscore, model.id)
  end

  # def default_url
  #   "manifest.csv"
  # end

  def extension_whitelist
    %w[csv]
  end

  def content_type_whitelist
    %w[text/csv text/comma-separated-values]
  end

  # def manifest(arg)
  #   # processing
  # end

  # Create different versions of your uploaded files:
  # version :manifest do
  #   process :validate => true
  # end

  # def filename
  #   @original_filename
  # end
end
