# frozen_string_literal: true

desc 'Task to be called by a cron to add cover/representatives to Monographs (ISBN lookup)'
namespace :heliotrope do
  task :tmm_upload_monograph_representatives, [:publisher, :monograph_files_dir] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:tmm_upload_monograph_representatives[michigan, /path/to/tmm_csv_dir]"

    # note: fail messages will be emailed to MAILTO by cron *unless* you use 2>&1 at the end of the job line
    fail "Monographs directory not found: '#{args.monograph_files_dir}'" unless Dir.exist?(args.monograph_files_dir)

    # need to ensure that we are finding Monographs from sub-presses (like gabii)
    all_presses = Press.where(parent: Press.where(subdomain: args.publisher).first).map(&:subdomain).push(args.publisher)
    all_presses = '("' + all_presses.join('" OR "') + '")'

    Pathname(args.monograph_files_dir).children.each do |mono_dir|
      next if !mono_dir.directory? || mono_dir.basename.to_s.start_with?('.')

      # note we're taking the first 10 or more contiguous digits in the file name to be an ISBN
      isbn = mono_dir.basename.to_s[/[0-9]{10,}/]
      if isbn.blank?
        puts "NO ISBN FOUND FOR #{mono_dir} ... SKIPPING"
        next
      end

      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +isbn_numeric:#{isbn} AND +press_sim:#{all_presses}", rows: 100_000)

      if docs.count > 1 # shouldn't happen
        puts "More than 1 Monograph found using ISBN in #{mono_dir.basename} ... SKIPPING ROW"
        docs.each { |doc| puts Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id) }
        puts
        next
      end

      if docs.count == 0
        puts "No Monograph found using ISBN in #{mono_dir.basename} ... SKIPPING"
        next
      end

      puts "1 Monograph found using ISBN in #{mono_dir.basename} ... CHECKING FILES"
      doc = docs.first

      # Cover images
      image_file_paths = Pathname.glob(mono_dir + '*.{bmp,jpg,jpeg,png,gif}')
      if image_file_paths.count > 1
        puts "    More than one image file found in #{mono_dir.basename} ... SKIPPING COVER PROCESSING"
        next
      end

      if image_file_paths.count == 1 && doc['representative_id_ssim'].blank?
        puts "    No cover found. Adding cover using #{image_file_paths.first}"
        Tmm::FileService.add(doc: doc, file: image_file_paths.first, kind: :cover)
      end

      if image_file_paths.count == 1 && doc['representative_id_ssim'].present?
        if Tmm::FileService.replace?(file_set_id: doc['representative_id_ssim'].first, new_file_path: image_file_paths.first)
           puts "    Current cover will be replaced with new #{image_file_paths.first}"
           Tmm::FileService.replace(file_set_id: doc['representative_id_ssim'].first, new_file_path: image_file_paths.first)
        end
      end

      # EPUBs
      epub_file_paths = Pathname.glob(mono_dir + '*.epub')
      if epub_file_paths.count > 1
        puts "    More than one EPUB file found in #{mono_dir.basename} ... SKIPPING EPUB PROCESSING"
        next
      end

      if epub_file_paths.count == 1
        file_set_id = FeaturedRepresentative.where(work_id: doc.id, kind: 'epub').first&.file_set_id

        if file_set_id.blank?
          puts "    No epub found. Adding epub using #{epub_file_paths.first}"
          Tmm::FileService.add(doc: doc, file: epub_file_paths.first, kind: :epub, downloadable: true)

        elsif Tmm::FileService.replace?(file_set_id: file_set_id, new_file_path: epub_file_paths.first)
          puts "    Current epub will be replaced with new #{epub_file_paths.first}"
          Tmm::FileService.replace(file_set_id: file_set_id, new_file_path: epub_file_paths.first)
        end
      end

      # PDF Ebooks
      pdf_file_paths = Pathname.glob(mono_dir + '*.pdf')
      if pdf_file_paths.count > 1
        puts "    More than one PDF file found in #{mono_dir.basename} ... SKIPPING PDF_EBOOK PROCESSING"
        next
      end

      if pdf_file_paths.count == 1
        file_set_id = FeaturedRepresentative.where(work_id: doc.id, kind: 'pdf_ebook').first&.file_set_id

        if file_set_id.blank?
          puts "    No pdf_ebook found. Adding pdf_ebook using #{pdf_file_paths.first}"
          Tmm::FileService.add(doc: doc, file: pdf_file_paths.first, kind: :pdf, downloadable: true)

        elsif Tmm::FileService.replace?(file_set_id: file_set_id, new_file_path: pdf_file_paths.first)
          puts "    Current pdf will be replaced with new #{pdf_file_paths.first}"
          Tmm::FileService.replace(file_set_id: file_set_id, new_file_path: pdf_file_paths.first)
        end
      end
    end
  end
end
