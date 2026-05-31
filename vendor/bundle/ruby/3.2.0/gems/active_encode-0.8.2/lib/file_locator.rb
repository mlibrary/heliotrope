# frozen_string_literal: true
require 'addressable/uri'
require 'aws-sdk-s3'

class FileLocator
  attr_reader :source

  class S3File
    attr_reader :bucket, :key

    def initialize(uri)
      uri = Addressable::URI.parse(uri)
      @bucket = URI.decode(uri.host)
      @key = URI.decode(uri.path).sub(%r{^/*(.+)/*$}, '\1')
    end

    def object
      @object ||= Aws::S3::Object.new(bucket_name: bucket, key: key)
    end
  end

  def initialize(source)
    @source = source
  end

  def uri
    if @uri.nil?
      if source.is_a? File
        @uri = Addressable::URI.parse("file://#{URI.encode(File.expand_path(source))}")
      else
        encoded_source = source
        begin
          @uri = Addressable::URI.parse(encoded_source)
        rescue URI::InvalidURIError
          if encoded_source == source
            encoded_source = URI.encode(encoded_source)
            retry
          else
            raise
          end
        end

        @uri = Addressable::URI.parse("file://#{URI.encode(File.expand_path(source))}") if @uri.scheme.nil?
      end
    end
    @uri
  end

  def location
    case uri.scheme
    when 's3'
      S3File.new(uri).object.presigned_url(:get)
    when 'file'
      URI.decode(uri.path)
    else
      @uri.to_s
    end
  end

  def exist?
    case uri.scheme
    when 's3'
      S3File.new(uri).object.exists?
    when 'file'
      File.exist?(location)
    else
      false
    end
  end
  alias exists? exist?

  def reader
    case uri.scheme
    when 's3'
      S3File.new(uri).object.get.body
    when 'file'
      File.open(location, 'r')
    else
      Kernel.open(uri.to_s, 'r')
    end
  end

  def attachment
    case uri.scheme
    when 's3'
      uri
    when 'file'
      File.open(location, 'r')
    else
      location
    end
  end
end
