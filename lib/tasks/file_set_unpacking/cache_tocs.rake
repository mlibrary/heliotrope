# frozen_string_literal: true

desc 'Build Table of Contents caches for unpacked epubs and pdf_ebooks'
namespace :heliotrope do
  task cache_tocs: :environment do
    # This will take a loooong time to do on production.
    # It's probably faster to just re-run the unpack jobs with:
    # FeaturedRepresentative.where(kind: ['epub','pdf_ebook']).each {|fr| UnpackJob.perform_later(fr.file_set_id, fr.kind) };0
    # But if for instance you're just updating the toc cache rather than creating maybe this would be fine.
    # It's also handy way to see errors.
    # I'll leave it here as an example.
    # See HELIO-3277
    FeaturedRepresentative.where(kind: ['epub', 'pdf_ebook']).each do |fr|
      case fr.kind
      when 'epub'
        EbookTableOfContentsCache.find_by(noid: fr.file_set_id)&.destroy
        epub = EPub::Publication.from_directory(UnpackService.root_path_from_noid(fr.file_set_id, 'epub'))
        intervals = epub&.rendition&.intervals
        if intervals.nil? || intervals.empty?
          p "#{DateTime.now.utc} ERROR: can't cache toc for epub #{fr.file_set_id} no intervals found"
        else
          EbookTableOfContentsCache.create(noid: epub.id, toc: intervals.map { |i| i.to_h_for_toc }.to_json)
          p "#{DateTime.now.utc} toc created for epub #{fr.file_set_id}"
        end
      when 'pdf_ebook'
        EbookTableOfContentsCache.find_by(noid: fr.file_set_id)&.destroy
        pdf = PDFEbook::Publication.from_path_id(UnpackService.root_path_from_noid(fr.file_set_id, 'pdf_ebook') + '.pdf', fr.file_set_id)
        intervals = pdf&.intervals
        if intervals.nil? || intervals.empty?
          p "#{DateTime.now.utc} ERROR: can't cache toc for pdf #{fr.file_set_id} no intervals found"
        else
          EbookTableOfContentsCache.create(noid: pdf.id, toc: intervals.map { |i| i.to_h_for_toc }.to_json)
          p "#{DateTime.now.utc} toc created for pdf #{fr.file_set_id}"
        end
      end
    end
  end
end
