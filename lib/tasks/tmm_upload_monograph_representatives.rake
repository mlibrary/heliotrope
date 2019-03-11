# frozen_string_literal: true

desc 'Task to be called by a cron to add cover/representatives to Monographs (ISBN lookup)'
namespace :heliotrope do
  task :tmm_upload_monograph_representatives, [:publisher, :monograph_files_dir] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:tmm_upload_monograph_representatives[michigan, /path/to/tmm_csv_dir]"

    # note: fail messages will be emailed to MAILTO by cron *unless* you use 2>&1 at the end of the job line
    fail "Monographs directory not found: '#{args.monograph_files_dir}'" unless Dir.exist?(args.monograph_files_dir)

    # need to ensure that we are finding Monographs from sub-presses (like gabii)
    all_presses = Press.where(parent: Press.where(subdomain: args.publisher).first).map(&:subdomain).push(args.publisher)

    Pathname(args.monograph_files_dir).children.each do |mono_dir|
      next if !mono_dir.directory? || mono_dir.basename.to_s.start_with?('.')
      isbn = mono_dir.basename.to_s.sub(/\s*\(.+\)$/, '').delete('^0-9').strip
      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +isbn_numeric:#{isbn}", rows: 100_000)

      if docs.count > 1 # shouldn't happen
        puts "More than 1 Monograph found using ISBN in #{mono_dir.basename} ... SKIPPING ROW"
        docs.each { |doc| puts Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id) }
        puts
        next
      elsif docs.count == 0
        puts "No Monograph found using ISBN in #{mono_dir.basename} ... SKIPPING"
      else
        puts "1 Monograph found using ISBN in #{mono_dir.basename} ... CHECKING FILES"
        doc = docs.first

        # TODO: allow the replacement of cover or representative by checking if the file is different
        # TODO: maybe consolidate these file additions/replacements into a service

        image_file_paths = Pathname.glob(mono_dir + '*.{bmp,jpg,jpeg,png,gif}')

        if image_file_paths.count > 1
          puts "    More than one image file found in #{mono_dir.basename} ... SKIPPING COVER PROCESSING"
          next
        elsif image_file_paths.count == 1 && doc['representative_id_ssim'].blank?
          puts "    No cover found. Adding cover using #{image_file_paths.first}"

          user = User.find_by(email: doc['depositor_tesim'].first)
          monograph = Monograph.find(doc.id)
          image_uploaded_file = Hyrax::UploadedFile.create(file: File.new(image_file_paths.first), user: user)
          attrs = {}
          attrs[:import_uploaded_files_ids] = [image_uploaded_file.id]
          attrs[:import_uploaded_files_attributes] = [{ representative_kind: 'cover' }]
          Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, Ability.new(user), attrs))
        end

        epub_file_paths = Pathname.glob(mono_dir + '*.epub')

        if epub_file_paths.count > 1
          puts "    More than one PDF file found in #{mono_dir.basename} ... SKIPPING EPUB PROCESSING"
          next
        elsif epub_file_paths.count == 1
          current_epub_rep = FeaturedRepresentative.where(monograph_id: doc.id, kind: 'epub').first&.file_set_id

          if current_epub_rep.blank?
            puts "    No epub found. Adding epub using #{epub_file_paths.first}"

            user = User.find_by(email: doc['depositor_tesim'].first)
            monograph = Monograph.find(doc.id)
            epub_uploaded_file = Hyrax::UploadedFile.create(file: File.new(epub_file_paths.first), user: user)

            attrs = {}
            attrs[:import_uploaded_files_ids] = [epub_uploaded_file.id]
            attrs[:import_uploaded_files_attributes] = [{ allow_download: 'yes', representative_kind: 'epub' }]
            Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, Ability.new(user), attrs))
          end
        end

        pdf_file_paths = Pathname.glob(mono_dir + '*.pdf')

        if pdf_file_paths.count > 1
          puts "    More than one PDF file found in #{mono_dir.basename} ... SKIPPING PDF_EBOOK PROCESSING"
          next
        elsif pdf_file_paths.count == 1
          current_pdf_rep = FeaturedRepresentative.where(monograph_id: doc.id, kind: 'pdf_ebook').first&.file_set_id

          if current_pdf_rep.blank?
            puts "    No pdf_ebook found. Adding pdf_ebook using #{pdf_file_paths.first}"

            user = User.find_by(email: doc['depositor_tesim'].first)
            monograph = Monograph.find(doc.id)
            pdf_uploaded_file = Hyrax::UploadedFile.create(file: File.new(pdf_file_paths.first), user: user)

            attrs = {}
            attrs[:import_uploaded_files_ids] = [pdf_uploaded_file.id]
            attrs[:import_uploaded_files_attributes] = [{ allow_download: 'yes', representative_kind: 'pdf_ebook' }]
            Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, Ability.new(user), attrs))
          end
        end
      end
    end
  end
end
