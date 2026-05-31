# frozen_string_literal: true

require "pathname"
require "digest/sha1"
require "digest/md5"

module BagIt
  # Requires response to bag_dir, tag_files, bag_files
  module Manifest
    def encode_filename(s)
      s = s.gsub(/\r/, "%0D")
      s = s.gsub(/\n/, "%0A")
      s
    end

    # All tag files that are bag manifest files (manifest-[algorithm].txt)
    def manifest_files
      files = Dir[File.join(@bag_dir, "*")].select { |f|
        File.file?(f) && File.basename(f) =~ /^manifest-.*.txt$/
      }
      files
    end

    # A path to a manifest file of the specified algorithm
    def manifest_file(algo)
      File.join bag_dir, "manifest-#{algo}.txt"
    end

    # Generate manifest files for all the bag files
    def manifest!(algo: "default")
      # nuke all the existing manifest files
      manifest_files.each { |f| FileUtils.rm f }

      # manifest each tag file for each algorithm
      bag_files.each do |f|
        rel_path = encode_filename(Pathname.new(f).relative_path_from(Pathname.new(bag_dir)).to_s)

        write_checksum(checksum_algo: algo, relative_path: rel_path, file: f)
      end
      tagmanifest!
    end

    def write_checksum(checksum_algo:, relative_path:, file:)
      case checksum_algo
      when "sha1"
        write_sha1(file, relative_path)
      when "md5"
        write_md5(file, relative_path)
      when "sha256"
        write_sha256(file, relative_path)
      when "sha512"
        write_sha512(file, relative_path)
      when "default"
        write_sha1(file, relative_path)
        write_md5(file, relative_path)
      end
    end

    def write_sha1(f, rel_path)
      sha1 = Digest::SHA1.file f
      File.open(manifest_file(:sha1), "a") { |io| io.puts "#{sha1} #{rel_path}" }
    end

    def write_md5(f, rel_path)
      md5 = Digest::MD5.file f
      File.open(manifest_file(:md5), "a") { |io| io.puts "#{md5} #{rel_path}" }
    end

    def write_sha256(f, rel_path)
      sha256 = Digest::SHA256.file f
      File.open(manifest_file(:sha256), "a") { |io| io.puts "#{sha256} #{rel_path}" }
    end

    def write_sha512(f, rel_path)
      sha512 = Digest::SHA512.file f
      File.open(manifest_file(:sha512), "a") { |io| io.puts "#{sha512} #{rel_path}" }
    end

    # All tag files that are bag manifest files (tagmanifest-[algorithm].txt)
    def tagmanifest_files
      files = Dir[File.join(@bag_dir, "*")].select { |f|
        File.file?(f) && File.basename(f) =~ /^tagmanifest-.*.txt$/
      }
      files
    end

    # A path to a tagmanifest file of the specified algorithm
    def tagmanifest_file(algo)
      File.join bag_dir, "tagmanifest-#{algo}.txt"
    end

    # Generate manifest files for all the tag files (except the tag
    # manifest files)
    def tagmanifest!(tags = nil)
      tags = tag_files if tags.nil?

      # nuke all the existing tagmanifest files
      tagmanifest_files.each { |f| FileUtils.rm f }

      # ensure presence of manfiest files
      manifest_files.each do |manifest|
        tags << manifest unless tags.include?(manifest)
      end

      # ensure presence of bag info files
      tags << bag_info_txt_file unless tags.include?(bag_info_txt_file)
      tags << bagit_txt_file unless tags.include?(bagit_txt_file)

      # manifest each (non tagmanifest) tag file for each algorithm
      tags.each do |f|
        add_tag_file(Pathname.new(f).relative_path_from(Pathname.new(bag_dir)).to_s)
      end
      tag_files
    end

    def add_tag_file(path, src_path = nil)
      f = File.join(@bag_dir, path)
      raise "Tag file already in manifest: #{path}" if tag_files.include?(f)

      if !File.exist? f
        FileUtils.mkdir_p File.dirname(f)

        # write file
        if src_path.nil?
          File.open(f, "w") { |io| yield io }
        else
          FileUtils.cp src_path, f
        end
        # this adds the manifest and bag info files on initial creation
        # it must only run when the manifest doesn't already exist or it will
        # infinitely recall add_tag_file. Better way of doing this?
        tagmanifest!
      elsif !src_path.nil?
        raise "Tag file already exists, will not overwrite: #{path}\n Use add_tag_file(path) to add an existing tag file."
      end

      data = File.open(f, &:read)
      rel_path = Pathname.new(f).relative_path_from(Pathname.new(bag_dir)).to_s

      # sha1
      sha1 = Digest::SHA1.hexdigest data
      File.open(tagmanifest_file(:sha1), "a") { |io| io.puts "#{sha1} #{rel_path}" }

      # md5
      md5 = Digest::MD5.hexdigest data
      File.open(tagmanifest_file(:md5), "a") { |io| io.puts "#{md5} #{rel_path}" }
      tag_files
    end

    def remove_tag_file(path)
      tags = tag_files
      raise "Tag file is not in manifest: #{path}" unless tags.include?(File.join(@bag_dir, path))
      tags.delete(File.join(@bag_dir, path))
      tagmanifest!(tags)
    end

    def delete_tag_file(path)
      filepath = File.join(@bag_dir, path)
      raise "Tag file does not exist: #{path}" unless File.exist? filepath
      remove_tag_file(path) if tag_files.include?(path)
      FileUtils.rm filepath
    end

    # Returns true if all present manifested files' message digests
    # match the actual message digest
    def fixed?
      (manifest_files + tagmanifest_files).all? do |mf|
        # extract the algorithm
        mf =~ /manifest-(.+).txt$/

        algo = case Regexp.last_match(1)
               when /sha1/i
                 Digest::SHA1
               when /md5/i
                 Digest::MD5
               else
                 :unknown
        end

        # check it, an unknown algorithm is always true
        if algo == :unknown
          true
        else
          lines = File.open(mf, &:readlines)

          lines.all? do |line|
            manifested_digest, path = line.chomp.split(/\s+/, 2)
            actual_digest = File.open(File.join(@bag_dir, path)) { |io| algo.hexdigest io.read }
            actual_digest == manifested_digest
          end

        end
      end
    end
  end
end
