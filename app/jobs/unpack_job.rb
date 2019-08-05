# frozen_string_literal: true

require 'zip'

class UnpackJob < ApplicationJob
  queue_as :unpack

  def perform(id, kind)
    file_set = FileSet.find id
    raise "No file_set for #{id}" if file_set.nil?

    root_path = UnpackService.root_path_from_noid(id, kind)

    # A rake task run via nightly cron will delete these so we can avoid
    # problems with puma holding open file handles making deletion fail, HELIO-2015
    FileUtils.move(root_path, UnpackService.remove_path_from_noid(id, kind)) if Dir.exist? root_path

    file = Tempfile.new(id)
    file.write(file_set.original_file.content.force_encoding("utf-8"))
    file.close

    case kind
    when 'epub'
      unpack_epub(id, root_path, file)
      create_search_index(root_path)
      epub_webgl_bridge(id, root_path, kind)
      MinimalEpubJob.perform_later(root_path)
    when 'webgl'
      unpack_webgl(id, root_path, file)
      epub_webgl_bridge(id, root_path, kind)
    when 'map'
      unpack_map(id, root_path, file)
    else
      Rails.logger.error("Can't unpack #{kind} for #{id}")
    end
  end

  private

    def epub_webgl_bridge(id, root_path, kind)
      # Edge case for epubs with POI (Point of Interest) to map to CFI for a webgl (gabii)
      # See 1630
      monograph_id = FeaturedRepresentative.where(file_set_id: id)&.first&.monograph_id
      case kind
      when 'epub'
        if FeaturedRepresentative.where(monograph_id: monograph_id, kind: 'webgl')&.first.present?
          EPub::BridgeToWebgl.construct_bridge(EPub::Publication.from_directory(root_path))
        end
      when 'webgl'
        epub_id = FeaturedRepresentative.where(monograph_id: monograph_id, kind: 'epub')&.first&.file_set_id
        if epub_id.present?
          EPub::BridgeToWebgl.construct_bridge(EPub::Publication.from_directory(UnpackService.root_path_from_noid(epub_id, 'epub')))
        end
      end
    end

    def unpack_epub(id, root_path, file)
      Zip::File.open(file.path) do |zip_file|
        zip_file.each do |entry|
          make_path_entry(root_path, entry.name)
          entry.extract(File.join(root_path, entry.name))
        end
      end
    rescue Zip::Error
      raise "EPUB #{id} is corrupt."
    end

    def create_search_index(root_path)
      sql_lite = EPub::SqlLite.from_directory(root_path)
      sql_lite.create_table
      sql_lite.load_chapters
    end

    def unpack_webgl(id, root_path, file)
      Zip::File.open(file.path) do |zip_file|
        zip_file.each do |entry|
          # We don't want to include the root directory, it could be named anything.
          parts = entry.name.split(File::SEPARATOR)
          without_parent = parts.slice(1, parts.length).join(File::SEPARATOR)
          make_path_entry(root_path, without_parent)
          entry.extract(File.join(root_path, without_parent))
        end
      end
    rescue Zip::Error
      raise "Webgl #{id} is corrupt."
    end

    def make_path_entry(root_path, file_entry)
      FileUtils.mkdir_p(root_path) unless Dir.exist?(root_path)
      dir = root_path
      file_entry.split(File::SEPARATOR).each do |sub_dir|
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        dir = File.join(dir, sub_dir)
      end
    end

    def unpack_map(id, root_path, file)
      Zip::File.open(file.path) do |zip_file|
        zip_file.each do |entry|
          # We don't want to include the root directory, it could be named anything.
          parts = entry.name.split(File::SEPARATOR)
          without_parent = parts.slice(1, parts.length).join(File::SEPARATOR)
          make_path_entry(root_path, without_parent)
          entry.extract(File.join(root_path, without_parent))
        end
      end
    rescue Zip::Error
      raise "Map #{id} is corrupt."
    end
end
