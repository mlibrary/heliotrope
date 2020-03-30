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

      # in general `qpf` (linearize_pdf) raises (sometimes insignificant) errors the most, so do it last
      create_pdf_chapters(id, root_path, file)
      linearize_pdf(root_path, file)
    end

    def create_pdf_chapters(id, root_path, file) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      return unless system("which pdfseparate > /dev/null 2>&1") && system("which pdfunite > /dev/null 2>&1")

      # Blow away any PDFIntervalRecord associated with this noid
      # since the structure may have changed
      begin
        PDFIntervalRecord.find(noid: id).destroy
      rescue ActiveRecord::RecordNotFound
      end

      # Grab the ToC as is done for the catalog ToC tab... note the force_encoding("utf-8") is not done here cause...
      # it's not done in Sighrax::Asset.content() which feeds the normal ToC creation, so I assume it's OK without...
      # for this purpose
      pdf_ebook_presenter = PDFEbookPresenter.new(PDFEbook::Publication.from_string_id(FileSet.find(id).original_file.content, id))
      return unless pdf_ebook_presenter.intervals?

      chapters = []
      pdf_ebook_presenter.intervals.each do |interval|
        chapters << { level: interval.level,
                      start_page: interval.cfi.gsub('page=', '').to_i }
      end

      # Naively run through and assume each section ends on the page before the next one starts.
      # This makes books with a cleaner layout look better at the expense of a few problem corner cases.
      last_level = 0
      chapters_out = []
      chapters.each_with_index do |chapter, index|
        chapters_out[index] = chapter

        if index.zero?
        elsif chapter[:level] > last_level
        elsif chapter[:level] == last_level
          chapters_out[index - 1][:end_page] = chapters_out[index - 1][:start_page] == chapter[:start_page] ? chapter[:start_page] : chapter[:start_page] - 1
        elsif chapter[:level] < last_level
          # if we just moved back up to a higher ToC level (lower number!), the last chapter/section is finished,...
          # as are any previous sections on this higher ToC level
          chapters_out[index - 1][:end_page] = chapters_out[index - 1][:start_page] == chapter[:start_page] ? chapter[:start_page] : chapter[:start_page] - 1
          chapters_out.map do |chapter_out|
            if chapter_out[:end_page].blank? && chapter_out[:level] == chapter[:level]
              chapter_out[:end_page] = chapters_out[index - 1][:start_page] == chapter[:start_page] ? chapter[:start_page] : chapter[:start_page] - 1
              break
            end
          end
        end
        last_level = chapter[:level]
      end

      chapter_dir = File.join(root_path + '_chapters')
      # if there is a pre-existing chapter_dir schedule it for deletion
      FileUtils.move(chapter_dir, UnpackService.remove_path_from_noid(id, 'pdf_ebook_chapters')) if Dir.exist? chapter_dir
      FileUtils.mkdir_p chapter_dir unless Dir.exist? chapter_dir

      chapters_out.each_with_index do |chapter_out, index|
        # some very dodgy ToC's can tie up a worker for a very, very long time with links to page 0, `pdfunite` eventually fails somehow
        raise "This ToC has bookmarks pointing to page 0" if chapter_out[:start_page] == 0 || chapter_out[:end_page] == 0
        # now that Travis is using Xenial the default poppler-utils allows the %06d format specifier, zero-padding...
        # to 6 digits and bypassing sort problems when assembling the pages into section files
        if chapter_out[:end_page].present?
          run_command("pdfseparate -f #{chapter_out[:start_page]} -l #{chapter_out[:end_page]} #{file.path} #{chapter_dir}/#{id}_page_%06d.pdf")
        else
          run_command("pdfseparate -f #{chapter_out[:start_page]} #{file.path} #{chapter_dir}/#{id}_page_%06d.pdf")
        end
        run_command("pdfunite #{chapter_dir}/#{id}_page_*.pdf #{chapter_dir}/#{index}.pdf")
        # clean up page files before next chapter is built
        Dir.glob("#{chapter_dir}/#{id}_page_*.pdf").each { |page_file| File.delete(page_file) }
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
