# frozen_string_literal: true

desc "upload and add downloadable EPUB representatives to Monographs based on the EPUB file name matching a unique Monogprah's ISBN"
namespace :heliotrope do
  task :replace_epubs_via_isbn, [:publisher, :directory] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:replace_epubs_via_isbn[michigan, /path/to/epub/files/dir]"
    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    epub_file_paths = Dir.glob(File.join(args.directory, '*.epub')).sort

    added_count = 0
    replaced_count = 0

    epub_file_paths.each do |epub_file_path|
      epub_base_name = File.basename(epub_file_path, '.epub')

      # we expect the numeric component of the image file name to uniquely identify a Monograph within this publisher by ISBN
      # sometimes other digits are present after the ISBN (relating to, e.g. compression level or file version). Remove them.
      isbn = pdf_base_name.delete('^0-9')[0, 13].strip

      if isbn.blank?
        puts "No number present in EPUB file #{epub_base_name}.epub ...................... SKIPPING"
        next
      else
        matches = Monograph.where(press_sim: args.publisher, isbn_numeric: isbn)

        if matches.count.zero?
          puts "No Monograph found for EPUB file #{epub_base_name}.epub ...................... SKIPPING"
          next
        elsif matches.count > 1 # should be impossible
          puts "More than 1 Monograph found for EPUB file #{epub_base_name}.epub ...................... SKIPPING"
          next
        else
          monograph = matches.first

          current_epub_rep = FeaturedRepresentative.where(work_id: monograph.id, kind: 'epub').first&.file_set_id

          if current_epub_rep.present?
            # here we replace the current EPUB representative FileSet's file and recharacterize, create new derivatives
            replaced_count += 1
            puts "Monograph with NOID #{monograph.id} matching EPUB file #{epub_base_name}.epub has an EPUB representative ...... REPLACING"

            f = FileSet.find(current_epub_rep)
            f.files.each(&:delete)

            # f now contains references to tombstoned files, so pull the FileSet object again to avoid any...
            # Ldp::Gone errors in Hydra::Works::AddFileToFileSet
            f = FileSet.find(current_epub_rep)

            now = Hyrax::TimeService.time_in_utc
            f.date_uploaded = now
            f.date_modified = now
            f.label = File.basename(epub_file_path)
            f.title = [File.basename(epub_file_path)]
            f.allow_download = 'yes'
            f.save!

            Hydra::Works::AddFileToFileSet.call(f, File.open(epub_file_path), :original_file)

            # note: CharacterizeJob will always queue up CreateDerivativesJob,...
            # and also queues up UnpackJob if the file being replaced is a FeaturedRepresentative
            CharacterizeJob.perform_later(f, f.original_file.id, epub_file_path)
          else
            # here we upload and set EPUB FeaturedRepresentative
            added_count += 1
            puts "Monograph with NOID #{monograph.id} matching EPUB file #{epub_base_name}.epub has no EPUB representative ...... ADDING"

            user = User.find_by(email: monograph.depositor)

            epub_uploaded_file = Hyrax::UploadedFile.create(file: File.new(epub_file_path), user: user)

            attrs = {}
            attrs[:import_uploaded_files_ids] = [epub_uploaded_file.id]
            attrs[:import_uploaded_files_attributes] = [{ allow_download: 'yes', representative_kind: 'epub' }]
            Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, Ability.new(user), attrs))
          end
        end
      end
    end

    puts "\nDONE: #{added_count.to_s} EPUB rep(s) added, #{replaced_count.to_s} EPUB rep(s) replaced"
  end
end
