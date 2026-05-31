# frozen_string_literal: true

require "bagit/fetch"
require "bagit/file"
require "bagit/info"
require "bagit/manifest"
require "bagit/string"
require "bagit/valid"

module BagIt
  class FileFinder
    def self.find(dir)
      raise NotImplementedError
    end
  end

  class StandardFileFinder < FileFinder
    def self.find(dir)
      Dir[File.join(dir, "**", "*")].select { |f| File.file? f }
    end
  end

  class StandardWithHiddenFileFinder < FileFinder
    def self.find(dir)
      Dir.glob(File.join(dir, "**", "*"), File::FNM_DOTMATCH).select { |f| File.file? f }
    end
  end

  # Represents the state of a bag on a filesystem
  class Bag
    attr_reader :bag_dir
    attr_reader :detect_hidden

    include Validity # Validity functionality
    include Info # bagit & bag info functionality
    include Manifest # manifest related functionality
    include Fetch # fetch related functionality

    # Make a new Bag based at path
    def initialize(path, info = {}, _create = false, detect_hidden = false)
      @bag_dir = path
      @detect_hidden = detect_hidden
      @file_finder = @detect_hidden ? StandardWithHiddenFileFinder : StandardFileFinder

      # make the dir structure if it doesn't exist
      FileUtils.mkdir bag_dir unless File.directory? bag_dir
      FileUtils.mkdir data_dir unless File.directory? data_dir

      # write some tag info if its not there
      write_bagit("BagIt-Version" => SPEC_VERSION, "Tag-File-Character-Encoding" => "UTF-8") unless File.exist? bagit_txt_file

      write_bag_info(info) unless File.exist? bag_info_txt_file
    end

    # Return the path to the data directory
    def data_dir
      File.join @bag_dir, "data"
    end

    # Return the paths to each bag file relative to bag_dir
    def bag_files
      @file_finder.find(data_dir)
    end

    # Return the paths to each tag file relative to bag_dir
    def tag_files
      files = []
      if tagmanifest_files != []
        File.open(tagmanifest_files.first) do |f|
          f.each_line { |line| files << File.join(@bag_dir, line.split(" ")[1]) }
        end
      end
      files
    end

    # Add a bag file at the given path relative to data_dir
    def add_file(relative_path, src_path = nil)
      path = File.join(data_dir, relative_path)
      raise "Bag file exists: #{relative_path}" if File.exist? path
      FileUtils.mkdir_p File.dirname(path)

      f = if src_path.nil?
        File.open(path, "w") { |io| yield io }
      else
        FileUtils.cp src_path, path
      end
      write_bag_info
      f
    end

    # Remove a bag file at the given path relative to data_dir
    def remove_file(relative_path)
      path = File.join(data_dir, relative_path)
      raise "Bag file does not exist: #{relative_path}" unless File.exist? path
      FileUtils.rm path
    end

    # Retrieve the IO handle for a file in the bag at a given path relative to
    # data_dir
    def get(relative_path)
      path = File.join(data_dir, relative_path)
      return nil unless File.exist?(path)
      File.open(path)
    end

    # Test if this bag is empty (no files)
    def empty?
      bag_files.empty?
    end

    # Get all bag file paths relative to the data dir
    def paths
      bag_files.collect { |f| f.sub(data_dir + "/", "") }
    end

    # Get the Oxum for the payload files
    def payload_oxum
      bytes = 0
      bag_files.each do |f|
        # TODO: filesystem quirks? Are we getting the stream size or the size on disk?
        bytes += File.size(f)
      end
      bytes.to_s + "." + bag_files.count.to_s
    end

    # Remove all empty directory trees from the bag
    def gc!
      Dir.entries(data_dir).each do |f|
        unless %w[.. .].include? f
          abs_path = File.join data_dir, f
          File.clean abs_path
        end
      end
    end
  end
end
