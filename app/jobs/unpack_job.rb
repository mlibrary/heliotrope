# frozen_string_literal: true

class UnpackJob < ApplicationJob
  queue_as :unpack

  def perform(id, kind)
    file_set = FileSet.find id
    raise "No file_set for #{id}" if file_set.nil?

    root_path = Hyrax::DerivativePath.new(id).derivative_path + kind

    FileUtils.remove_entry_secure(root_path) if Dir.exist? root_path

    file = Tempfile.new(id)
    file.write(file_set.original_file.content.force_encoding("utf-8"))
    file.close

    case kind
    when 'epub'
      unpack_epub(id, root_path, file)
    when 'webgl'
      unpack_webgl(id, root_path, file)
    else
      Rails.logger.error("Can't unpack #{kind} for #{id}")
    end

    # Edge case for epubs with POI (Point of Interest) to map to CFI for a webgl (gabii)
    # See 1630
    # EPub::BridgeToWebgl.cache(publication) # if epub[:webgl]
  end

  private

    def unpack_epub(id, root_path, file)
      begin
        Zip::File.open(file.path) do |zip_file|
          zip_file.each do |entry|
            make_path_entry(root_path, entry.name)
            entry.extract(File.join(root_path, entry.name))
          end
        end
      rescue Zip::Error
        raise "EPUB #{id} is corrupt."
      end

      sql_lite = EPub::SqlLite.from_directory(root_path)
      sql_lite.create_table
      sql_lite.load_chapters(root_path)
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
end
