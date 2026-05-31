# frozen_string_literal: true

require "open-uri"

module BagIt
  module Fetch
    def fetch_txt_file
      File.join @bag_dir, "fetch.txt"
    end

    def add_remote_file(url, path, size, sha1, md5)
      File.open(fetch_txt_file, "a") { |io| io.puts "#{url} #{size || "-"} #{path}" }
      File.open(manifest_file("sha1"), "a") { |io| io.puts "#{sha1} #{File.join "data", path}" }
      File.open(manifest_file("md5"), "a") { |io| io.puts "#{md5} #{File.join "data", path}" }
    end

    # feth all remote files
    def fetch!
      File.open(fetch_txt_file) do |io|
        io.readlines.each do |line|
          (url, _length, path) = line.chomp.split(/\s+/, 3)

          add_file(path) do |file_io|
            file_io.write URI.open(url)
          end
        end
      end

      rename_old_fetch_txt(fetch_txt_file)
      move_current_fetch_txt(fetch_txt_file)
    end

    def rename_old_fetch_txt(fetch_txt_file)
      Dir["#{fetch_txt_file}.?*"].sort.reverse_each do |f|
        if f =~ /fetch.txt.(\d+)$/
          new_f = File.join File.dirname(f), "fetch.txt.#{Regexp.last_match(1).to_i + 1}"
          FileUtils.mv f, new_f
        end
      end
    end

    def move_current_fetch_txt(fetch_txt_file)
      FileUtils.mv fetch_txt_file, "#{fetch_txt_file}.0"
    end
  end
end
