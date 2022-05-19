# frozen_string_literal: true

desc "upload and add downloadable pdf_ebook representatives to Monographs based on the PDF file name matching a unique Monogprah's ISBN"
namespace :heliotrope do
  task :replace_pdf_ebooks_via_isbn, [:publisher, :directory] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:replace_pdf_ebooks_via_isbn[michigan, /path/to/pdf/files/dir]"
    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    pdf_file_paths = Dir.glob(File.join(args.directory, '*.pdf')).sort

    added_count = 0
    replaced_count = 0

    pdf_file_paths.each do |pdf_file_path|
      pdf_base_name = File.basename(pdf_file_path, '.pdf')

      # we expect the numeric component of the image file name to uniquely identify a Monograph within this publisher by ISBN
      # sometimes other digits are present after the ISBN (relating to, e.g. compression level or file version). Remove them.
      isbn = pdf_base_name.delete('^0-9')[0, 13].strip

      if isbn.blank?
        puts "No number present in PDF file #{pdf_base_name}.pdf ...................... SKIPPING"
        next
      else
        matches = Monograph.where(press_sim: args.publisher, isbn_numeric: isbn)

        if matches.count.zero?
          puts "No Monograph found for PDF file #{pdf_base_name}.pdf ...................... SKIPPING"
          next
        elsif matches.count > 1 # should be impossible
          puts "More than 1 Monograph found for PDF file #{pdf_base_name}.pdf ...................... SKIPPING"
          next
        else
          monograph = matches.first

          current_pdf_rep = FeaturedRepresentative.where(work_id: monograph.id, kind: 'pdf_ebook').first&.file_set_id

          if current_pdf_rep.present?
            # here we replace the current pdf_ebook representative FileSet's file and recharacterize, create new derivatives
            replaced_count += 1
            puts "Monograph with NOID #{monograph.id} matching PDF file #{pdf_base_name}.pdf has a pdf_ebook representative ...... REPLACING"

            f = FileSet.find(current_pdf_rep)
            f.files.each(&:delete)

            # f now contains references to tombstoned files, so pull the FileSet object again to avoid any...
            # Ldp::Gone errors in Hydra::Works::AddFileToFileSet
            f = FileSet.find(current_pdf_rep)

            now = Hyrax::TimeService.time_in_utc
            f.date_uploaded = now
            f.date_modified = now
            f.label = File.basename(pdf_file_path)
            f.title = [File.basename(pdf_file_path)]
            f.allow_download = 'yes'
            f.save!

            Hydra::Works::AddFileToFileSet.call(f, File.open(pdf_file_path), :original_file)

            # note: CharacterizeJob will always queue up CreateDerivativesJob,...
            # and also queues up UnpackJob if the file being replaced is a FeaturedRepresentative
            CharacterizeJob.perform_later(f, f.original_file.id, pdf_file_path)
          else
            # here we upload and set pdf_ebook FeaturedRepresentative
            added_count += 1
            puts "Monograph with NOID #{monograph.id} matching PDF file #{pdf_base_name}.pdf has no pdf_ebook representative ...... ADDING"

            user = User.find_by(email: monograph.depositor)

            pdf_uploaded_file = Hyrax::UploadedFile.create(file: File.new(pdf_file_path), user: user)

            attrs = {}
            attrs[:import_uploaded_files_ids] = [pdf_uploaded_file.id]
            attrs[:import_uploaded_files_attributes] = [{ allow_download: 'yes', representative_kind: 'pdf_ebook' }]
            Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, Ability.new(user), attrs))
          end
        end
      end
    end

    puts "\nDONE: #{added_count.to_s} PDF rep(s) added, #{replaced_count.to_s} PDF rep(s) replaced"
  end
end
