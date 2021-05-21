# frozen_string_literal: true

class LogoPathUploader < CarrierWave::Uploader::Base
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

  # Prawn only allows jpg and png images so only allow these as they have to be used in watermark cover pages
  def extension_whitelist
    %w[jpg jpeg png]
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  # def filename
  #   "something.jpg" if original_filename
  # end
end
