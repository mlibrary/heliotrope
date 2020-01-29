# frozen_string_literal: true

desc "upload and add thumbnail representatives (covers) to Monographs based on the image file name matching a unique Monograph's ISBN"
namespace :heliotrope do
  task :replace_covers_via_isbn, [:publisher, :directory] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:replace_covers_via_isbn[michigan, /path/to/image/files/dir]"
    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    image_file_paths = Dir.glob(File.join(args.directory, '*.{bmp,jpg,jpeg,png,gif}')).sort

    added_count = 0
    replaced_count = 0

    image_file_paths.each do |image_file_path|
      image_extension = File.extname(image_file_path)
      image_base_name = File.basename(image_file_path, image_extension)

      # we expect the numeric component of the image file name to uniquely identify a Monograph within this publisher by ISBN
      isbn = image_base_name.delete('^0-9').strip

      if isbn.blank?
        puts "No number present in image file #{image_base_name}#{image_extension} ...................... SKIPPING"
        next
      else
        matches = Monograph.where(press_sim: args.publisher, isbn_numeric: isbn)

        if matches.count.zero?
          puts "No Monograph found for image file #{image_base_name}#{image_extension} ...................... SKIPPING"
          next
        elsif matches.count > 1 # should not happen within a given publisher
          puts "More than 1 Monograph found for image file #{image_base_name}#{image_extension} ...................... SKIPPING"
          next
        else
          monograph = matches.first

          current_cover = FileSet.where(id: monograph.thumbnail_id).first

          if current_cover.present?
            # here we replace the current thumbnail/representative FileSet's file and recharacterize
            replaced_count += 1
            puts "Monograph with NOID #{monograph.id} matching image file #{image_base_name}#{image_extension} has an existing cover ...... REPLACING"

            current_cover.files.each(&:delete)

            # current_cover now contains references to tombstoned files, so pull the FileSet object again to avoid any...
            # Ldp::Gone errors in Hydra::Works::AddFileToFileSet
            f = FileSet.find(monograph.thumbnail_id)
            now = Hyrax::TimeService.time_in_utc
            f.date_uploaded = now
            f.date_modified = now
            f.label = File.basename(image_file_path)
            f.title = [File.basename(image_file_path)]
            f.save!

            Hydra::Works::AddFileToFileSet.call(f, File.open(image_file_path), :original_file)

            # note: CharacterizeJob will always queue up CreateDerivativesJob,...
            # and also queues up UnpackJob if the file being replaced is a FeaturedRepresentative
            CharacterizeJob.perform_later(f, f.original_file.id, image_file_path)
          else
            # here we upload and set Monograph's thumbnail_id and representative_id, unlikely to happen
            added_count += 1
            puts "Monograph with NOID #{monograph.id} matching image file #{image_base_name}#{image_extension} has no cover ...... ADDING"

            user = User.find_by(email: monograph.depositor)

            image_uploaded_file = Hyrax::UploadedFile.create(file: File.new(image_file_path), user: user)

            attrs = {}
            attrs[:import_uploaded_files_ids] = [image_uploaded_file.id]
            attrs[:import_uploaded_files_attributes] = [{ representative_kind: 'cover' }]
            Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, Ability.new(user), attrs))
          end
        end
      end
    end

    puts "\nDONE: #{added_count.to_s} cover(s) added, #{replaced_count.to_s} cover(s) replaced"
  end
end
