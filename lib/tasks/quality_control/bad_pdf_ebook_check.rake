# frozen_string_literal: true

desc 'ouput a report of bad pdf ebooks'
namespace :heliotrope do
  task bad_pdf_ebook_check: :environment do
    # We just want to make sure that pdf_ebooks that have been processed by unpacking are ok.
    # We don't want to have to fallback to parsing them for toc or hitting ActiveFedora
    # to fetch them ever. So if they show up on this report it's possible that
    # they're malformed in some way and should be fixed.
    # HELIO-3277

    # This probably is too complicated for a rake task and should be a service with specs

    # USAGE: bundle exec rake heliotrope:bad_pdf_ebook_check > /tmp/bad_pdfs_report.csv

    checked_pdfs = []

    FeaturedRepresentative.where(kind: "pdf_ebook").each do |fr|
      check = OpenStruct.new

      check.noid = fr.file_set_id
      check.work_noid = fr.work_id

      root_path = UnpackService.root_path_from_noid(fr.file_set_id, "pdf_ebook")

      # Is the pdf in the derivatives directory?
      pdf = root_path + ".pdf"
      check.derivative = File.exist? pdf

      # Is it openable by Origami?
      pdf_ebook = PDFEbook::Publication.from_path_id(pdf, fr.file_set_id)
      check.openable = (pdf_ebook.class == PDFEbook::Publication)

      # Have pdf chapters been created?
      chapter_dir = File.join(root_path + '_chapters')
      check.chapters = Dir.glob(chapter_dir +"/*.pdf").count.positive?

      # Is the toc cached in the database?
      check.cached_toc = EbookTableOfContentsCache.find_by(noid: fr.file_set_id).present?

      # Save if there are any errors
      next if check.to_h.map{|k, v| "error" if v == false}.compact.count.zero?
      checked_pdfs << check
    end

    return if checked_pdfs.empty?

    # Create a report of bad pdfs
    monograph_ids = checked_pdfs.map { |check| check.work_noid }
    monograph_docs = ActiveFedora::SolrService.query("{!terms f=id}#{checked_pdfs.map { |check| check.work_noid }.join(",")}", rows: 10_000)
    output = CSV.generate do |csv|
      csv << ["press", "monograph noid", "title", "pdf noid", "has epub?", "is on the file system?", "is openable?", "has chapters?", "has cached toc?"]
      checked_pdfs.each do |check|
        doc = monograph_docs.map { |doc| doc if doc["id"] == check.work_noid }.compact.first
        press = doc["press_tesim"].first
        title = doc["title_tesim"].first
        epub = FeaturedRepresentative.where(work_id: check.work_noid, kind: "epub").first&.file_set_id || ""
        row = [
          press,
          check.work_noid,
          title,
          check.noid,
          epub,
          check.derivative ? "" : "error",
          check.openable ? "" : "error",
          check.chapters ? "" : "error",
          check.cached_toc ? "" : "error"
        ]
        csv << row
      end
    end

    puts output
  end
end
