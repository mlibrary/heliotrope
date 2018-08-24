# frozen_string_literal: true

require 'zip'

class MinimalEpubJob < ApplicationJob
  queue_as :minimize_epub

  def perform(root_path)
    epub = EPub::Publication.from_directory(root_path)
    return if epub.is_a? EPub::PublicationNullObject
    return unless epub.multi_rendition?

    # HELIO-2074. Fixed layout epubs are network intensive.
    # So we'll send the whole epub to CSB instead of it doing a GET for each page.
    # Make a "minimal" epub that has no page images or sqlite index that we can
    # repack and send to CSB as a single file.

    # The mimimize working directory
    minimal = File.join(root_path, epub.id + ".sm")
    # Clear the old .sm.epub if it exists.
    sm_epub = minimal + '.epub'
    FileUtils.rm sm_epub if Dir.exist? sm_epub

    minimal = File.join(root_path, epub.id + ".sm")

    system("cd #{root_path}; rsync -a --exclude '[0-9]*.png' --exclude '*.db' . #{minimal}")

    # update the spine
    lines = File.readlines("#{minimal}/OEBPS/content_fixed_scan.opf").each do |line|
      line.sub!(/href="(images\/\d+)/, %(href="/epubs/#{epub.id}/OEBPS/\\1))
    end
    File.open("#{minimal}/OEBPS/content_fixed_scan.opf", "w") do |file|
      file.puts lines
    end

    # update the XHTML
    Dir.glob("#{minimal}/OEBPS/xhtml/*fixed_scan.xhtml").each do |file|
      lines = File.readlines(file).each do |line|
        line.sub!(/src="\.\.\/(images\/\d+)/, %(src="/epubs/#{epub.id}/OEBPS/\\1))
      end
      File.open(file, "w") do |f|
        f.puts lines
      end
    end

    # repack the minimal epub
    system("cd #{minimal}; zip -Xq #{sm_epub} mimetype")
    system("cd #{minimal}; zip -rgq #{sm_epub} META-INF")
    system("cd #{minimal}; zip -rgq #{sm_epub} OEBPS")

    # remove the .sm working directory
    FileUtils.remove_entry_secure minimal if Dir.exist? minimal
  end
end
