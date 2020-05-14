# frozen_string_literal: true

require 'zip'
require 'open3'

class UnpackJob < ApplicationJob
  include Open3
  queue_as :unpack

  def perform(id, kind) # rubocop:disable Metrics/CyclomaticComplexity
    file_set = FileSet.find id
    raise "No file_set for #{id}" if file_set.nil?

    root_path = UnpackService.root_path_from_noid(id, kind)

    # A rake task run via nightly cron will delete these so we can avoid
    # problems with puma holding open file handles making deletion fail, HELIO-2015
    FileUtils.move(root_path, UnpackService.remove_path_from_noid(id, kind)) if Dir.exist? root_path
    # "Unpacked" PDFs are files, not directories
    FileUtils.move("#{root_path}.pdf", UnpackService.remove_path_from_noid(id, kind)) if File.exist? "#{root_path}.pdf"

    file = Tempfile.new(id)
    file.write(file_set.original_file.content.force_encoding("utf-8"))
    file.close

    case kind
    when 'epub'
      unpack_epub(id, root_path, file)
      create_search_index(root_path)
      epub_webgl_bridge(id, root_path, kind)
    when 'webgl'
      unpack_webgl(id, root_path, file)
      epub_webgl_bridge(id, root_path, kind)
    when 'interactive_map'
      unpack_map(id, root_path, file)
    when 'pdf_ebook'
      unpack_pdf(id, root_path, file)
    else
      Rails.logger.error("Can't unpack #{kind} for #{id}")
    end
  end

  private

    def unpack_pdf(id, root_path, file)
      # Need to make the dir for some tests to pass. This shouldn't ever be an issue
      # in real usage, but I'll put it here and not in the specs in case really weird
      # things happen with hydra-derivatives. I guess.
      FileUtils.mkdir_p File.dirname root_path unless Dir.exist? File.dirname root_path

      linearize_pdf(root_path, file)
      create_pdf_chapters(id, root_path, file)
    end

    def create_pdf_chapters(id, root_path, file) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return unless system("which qpdf > /dev/null 2>&1")
      return unless File.exist? "#{root_path}.pdf"

      # Grab the ToC as is done for the catalog ToC tab... note the force_encoding("utf-8") is not done here cause...
      # it's not done in Sighrax::Asset.content() which feeds the normal ToC creation, so I assume it's OK without...
      # for this purpose
      pdf_ebook_presenter = PDFEbookPresenter.new(PDFEbook::Publication.from_path_id(root_path + '.pdf', id))
      return unless pdf_ebook_presenter.intervals?

      # all the intervals have are start pages, so we'll gather those and then move on to calculating end pages
      chapters = []
      pdf_ebook_presenter.intervals.each do |interval|
        chapters << { level: interval.level,
                      start_page: interval.cfi.gsub('page=', '').to_i }
      end

      chapters.each_with_index do |chapter, index|
        chapters[0...index].map do |chapter_out|
          # if we just moved back up to a "higher" ToC level (lower level number!), then all previous sections on...
          # this ToC level or "below" (their nested children with a higher level number) are terminated.
          if chapter_out[:end_page].blank? && chapter_out[:level] >= chapter[:level]
            # Note we'll always include the first page of the following section, as there are inevitable edge cases...
            # (usually in smaller/lower subsections) where that page is needed, and we have no way to detect that.
            chapter_out[:end_page] = chapter[:start_page]
          end
        end
      end

      chapter_dir = File.join(root_path + '_chapters')
      # if there is a pre-existing chapter_dir schedule it for deletion
      FileUtils.move(chapter_dir, UnpackService.remove_path_from_noid(id, 'pdf_ebook_chapters')) if Dir.exist? chapter_dir
      FileUtils.mkdir_p chapter_dir unless Dir.exist? chapter_dir

      chapters.each_with_index do |chapter_out, index|
        raise "This ToC has bookmarks pointing to page 0" if chapter_out[:start_page] == 0 || chapter_out[:end_page] == 0
        if chapter_out[:end_page].present?
          run_command("qpdf --empty --pages #{file.path} #{chapter_out[:start_page]}-#{chapter_out[:end_page]} -- #{chapter_dir}/#{index}.pdf")
        else
          run_command("qpdf --empty --pages #{file.path} #{chapter_out[:start_page]}-z -- #{chapter_dir}/#{index}.pdf")
        end
      end
    end

    def linearize_pdf(root_path, file)
      if system("which qpdf > /dev/null 2>&1")
        # "Linearize" the pdf for x-sendfile and byte ranges, HELIO-3165
        # It's ok to linearize a pdf that's already been linearized
        run_command("qpdf --linearize #{file.path} #{root_path}.pdf")
      else
        FileUtils.copy(file, "#{root_path}.pdf")
      end
      # This is weird, but perms are -rw------- and they need to be -rw-rw-r--
      File.chmod 0664, "#{root_path}.pdf"
    end

    def run_command(command)
      stdin, stdout, stderr, wait_thr = popen3(command)
      stdin.close
      stdout.binmode
      out = stdout.read
      stdout.close
      err = stderr.read
      stderr.close
      # https://tools.lib.umich.edu/jira/browse/HELIO-3247
      raise "Unable to execute command \"#{command}\"\n#{err}\n#{out}" unless wait_thr.value.success? || err.include?('operation succeeded with warnings')
    end

    def epub_webgl_bridge(id, root_path, kind)
      # Edge case for epubs with POI (Point of Interest) to map to CFI for a webgl (gabii)
      # See 1630
      monograph_id = FeaturedRepresentative.where(file_set_id: id)&.first&.work_id
      case kind
      when 'epub'
        if FeaturedRepresentative.where(work_id: monograph_id, kind: 'webgl')&.first.present?
          EPub::BridgeToWebgl.construct_bridge(EPub::Publication.from_directory(root_path))
        end
      when 'webgl'
        epub_id = FeaturedRepresentative.where(work_id: monograph_id, kind: 'epub')&.first&.file_set_id
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
