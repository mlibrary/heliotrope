# frozen_string_literal: true

desc "iterate over a directory to add/replace representatives where filenames uniquely match a Monograph's ISBN"
namespace :heliotrope do
  task :replace_representatives_via_isbn, [:publisher, :directory] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:replace_representatives_via_isbn[michigan, /path/to/representative/files/dir]"
    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    file_paths = Dir.glob(File.join(args.directory, '*.{bmp,jpg,jpeg,png,gif,epub,pdf}')).sort

    covers_added_count = epubs_added_count = pdfs_added_count = 0
    covers_replaced_count = epubs_replaced_count = pdfs_replaced_count = 0

    file_paths.each do |file_path|
      file_extension = File.extname(file_path)
      file_base_name = File.basename(file_path, file_extension)

      # sometimes ISBN-named files have extra digits after an underscore, relating to compression, quality etc, e.g...
      # `9781407355555_optimize_80pct_70level.pdf`. Throw away anything after an underscore.
      matches = ObjectLookupService.matches(file_base_name.split('_').first, args.publisher)

      if matches.count.zero?
        puts "No Monograph found for file #{file_base_name}#{file_extension} ...................... SKIPPING"
        next
      elsif matches.count > 1 # should not happen within a given publisher
        puts "More than 1 Monograph found for file #{file_base_name}#{file_extension} ...................... SKIPPING"
        next
      else
        monograph = matches.first
        doc = SolrDocument.new(monograph.to_solr)

        if ['bmp', 'jpg', 'jpeg', 'png', 'gif'].include?(file_extension.delete('.'))
          current_cover = FileSet.where(id: monograph.thumbnail_id).first

          if current_cover.present?
            puts "Monograph with NOID #{monograph.id} matching image file #{file_base_name}#{file_extension} has an existing cover ...... REPLACING"
            Tmm::FileService.replace(file_set_id: current_cover.id, new_file_path: file_path)
            covers_replaced_count += 1
          else
            puts "Monograph with NOID #{monograph.id} matching image file #{file_base_name}#{file_extension} has no cover ...... ADDING"
            Tmm::FileService.add(doc: doc, file: file_path, kind: :cover)
            covers_added_count += 1
          end
        elsif file_extension == '.epub'
          current_epub_id = FeaturedRepresentative.where(work_id: monograph.id, kind: 'epub').first&.file_set_id

          if current_epub_id.present?
            puts "Monograph with NOID #{monograph.id} matching EPUB file #{file_base_name}.epub has an existing EPUB representative ...... REPLACING"
            Tmm::FileService.replace(file_set_id: current_epub_id, new_file_path: file_path)
            epubs_replaced_count += 1
          else
            puts "Monograph with NOID #{monograph.id} matching EPUB file #{file_base_name}.epub has no EPUB representative ...... ADDING"
            Tmm::FileService.add(doc: doc, file: file_path, kind: :epub)
            epubs_added_count += 1
          end
        elsif file_extension == '.pdf'
          current_pdf_id = FeaturedRepresentative.where(work_id: monograph.id, kind: 'pdf').first&.file_set_id

          if current_pdf_id.present?
            puts "Monograph with NOID #{monograph.id} matching PDF file #{file_base_name}.pdf has an existing PDF representative ...... REPLACING"
            Tmm::FileService.replace(file_set_id: current_epub_id, new_file_path: file_path)
            pdfs_replaced_count += 1
          else
            puts "Monograph with NOID #{monograph.id} matching PDF file #{file_base_name}.pdf has no PDF representative ...... ADDING"
            Tmm::FileService.add(doc: doc, file: file_path, kind: :pdf_ebook)
            pdfs_added_count += 1
          end
        end
      end
    end
    puts "\n\nDONE:\n#{covers_added_count} cover(s) added, #{covers_replaced_count} cover(s) replaced"
    puts "\n\nDONE:\n#{epubs_added_count} EPUB(s) added, #{epubs_replaced_count} EPUB(s) replaced"
    puts "\n\nDONE:\n#{pdfs_added_count} PDF(s) added, #{pdfs_replaced_count} PDF(s) replaced"
  end
end
