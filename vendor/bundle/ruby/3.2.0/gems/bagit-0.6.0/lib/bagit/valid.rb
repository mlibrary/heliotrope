# frozen_string_literal: true

require "validatable"
require "open-uri"
require "cgi"
require "logger"

module BagIt
  class Bag
    include Validatable
    validates_true_for :consistency, logic: proc { consistent? }
    validates_true_for :completeness, logic: proc { complete? }
  end

  module Validity
    def decode_filename(s)
      s = s.gsub("%0D", "\r")
      s = s.gsub("%0A", "\n")
      s
    end

    # Return true if the manifest cover all files and all files are
    # covered.
    def complete?
      logger = Logger.new(STDOUT)

      errors.add :completeness, "there are no manifest files" if manifest_files == []

      unmanifested_files.each do |file|
        logger.error("#{file} is present but not manifested".red)
        errors.add :completeness, "#{file} is present but not manifested"
      end

      empty_manifests.each do |file|
        logger.error("#{file} is manifested but not present".red)
        error_message = "#{file} is manifested but not present"
        if !detect_hidden && file.start_with?(File.join("data", "."))
          error_message += "; consider turning on hidden file detection"
        end
        errors.add :completeness, error_message
      end
      tag_empty_manifests.each do |file|
        logger.error("#{file} is a manifested tag but not present".red)
        errors.add :completeness, "#{file} is a manifested tag but not present"
      end

      errors.on(:completeness).nil?
    end

    def manifest_type(type)
      case type
      when /sha1/i
        Digest::SHA1
      when /md5/i
        Digest::MD5
      when /sha256/i
        Digest::SHA256
      when /sha384/i
        Digest::SHA384
      when /sha512/i
        Digest::SHA512
      else
        raise ArgumentError, "Algorithm #{manifest_type} is not supported."
      end
    end

    # Return true if all manifested files message digests match.
    def consistent?
      (manifest_files | tagmanifest_files).each do |mf|
        # get the algorithm implementation
        File.basename(mf) =~ /manifest-(.+).txt$/
        type = Regexp.last_match(1)
        algo = manifest_type(type)
        # Check every file in the manifest
        File.open(mf) do |io|
          io.each_line do |line|
            expected, path = line.chomp.split(/\s+/, 2)
            file = File.join(bag_dir, decode_filename(path))

            next unless File.exist? file
            actual = algo.file(file).hexdigest
            errors.add :consistency, "expected #{file} to have #{algo}: #{expected}, actual is #{actual}" if expected.downcase != actual
          end
        end
      end

      errors.on(:consistency).nil?
    end

    # Checks for validity against Payload-Oxum
    def valid_oxum?
      bag_info["Payload-Oxum"] == payload_oxum
    end

    protected

    # Returns all files in the instance that are not manifested
    def unmanifested_files
      mfs = manifested_files.map { |f| File.join bag_dir, f }
      bag_files.reject { |f| mfs.member? f }
    end

    # Returns a list of manifested files that are not present
    def empty_manifests
      bfs = bag_files
      manifested_files.reject { |f| bfs.member? File.join(bag_dir, f) }
    end

    # Returns a list of tag manifested files that are not present
    def tag_empty_manifests
      empty = []
      tag_manifested_files.each do |f|
        empty.push f unless File.exist?(File.join(bag_dir, f))
      end
      empty
    end

    # Returns a list of all files present in the manifest files
    def manifested_files
      manifest_files.inject([]) do |acc, mf|
        files = File.open(mf) { |io|
          io.readlines.map do |line|
            _digest, path = line.chomp.split(/\s+/, 2)
            decode_filename(path)
          end
        }

        (acc + files).uniq
      end
    end

    # Returns a list of all files in the tag manifest files
    def tag_manifested_files
      tagmanifest_files.inject([]) do |acc, mf|
        files = File.open(mf) { |io|
          io.readlines.map do |line|
            _digest, path = line.chomp.split(/\s+/, 2)
            path
          end
        }
        (acc + files).uniq
      end
    end
  end
end
