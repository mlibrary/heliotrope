# frozen_string_literal: true

class LogoPathUploader < CarrierWave::Uploader::Base
  # Cache inspection even when Rails.cache is disabled in development.
  DIMENSIONS_CACHE = ActiveSupport::Cache::MemoryStore.new(size: 1.megabyte)

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  # include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # What you put here is prepended to the logo_path.url, along with a preceeding '/'
  def store_dir
    "upload/#{model.class.to_s.underscore}/#{mounted_as}/#{model.subdomain}"
  end

  # explicitly set cache_dir as it defaults to 'uploads/tmp' and will thus create public/uploads. See #1013.
  def cache_dir
    'upload/tmp'
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  def default_url
    'fulcrum-white-50px.png'
  end

  def dimensions
    path = file&.path || Rails.root.join('app', 'assets', 'images', default_url).to_s
    stat = File.stat(path)
    cache_key = [path, stat.size, stat.mtime.to_f, stat.ctime.to_f]

    DIMENSIONS_CACHE.fetch(cache_key) do
      image = MiniMagick::Image.new(path)
      width, height = image.dimensions
      width, height = height, width if %w[LeftTop RightTop RightBottom LeftBottom].include?(image['%[orientation]'])
      { width: width, height: height }
    end
  rescue Errno::ENOENT, Errno::EACCES, MiniMagick::Error, MiniMagick::Invalid => error
    Rails.logger.warn("Unable to read press logo dimensions for #{path}: #{error.message}")
    {}
  end

  # Process files as they are uploaded:
  # process scale: [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process resize_to_fit: [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_whitelist
    %w[jpg jpeg gif png]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
