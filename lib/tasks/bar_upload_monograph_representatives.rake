# frozen_string_literal: true

desc 'Task to be called by a cron to add cover/representatives to Monographs (ISBN lookup)'
namespace :heliotrope do
  task :bar_upload_monograph_representatives, [:bar_files_dir] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:bar_upload_monograph_representatives[/path/to/bar_files_dir]"

    fail "Monographs directory not found: '#{args.bar_files_dir}'" unless Dir.exist?(args.bar_files_dir)

    Pathname(args.bar_files_dir).children.each do |bar_file|
      next unless bar_file.to_s.ends_with?('.pdf') || bar_file.to_s.ends_with?('.png')

      # note we're taking the first 10 or more contiguous digits in the file name to be an ISBN
      isbn = bar_file.basename.to_s[/[0-9]{10,}/]
      if isbn.blank?
        puts "NO ISBN FOUND FOR #{bar_file} ... SKIPPING"
        next
      end

      docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +isbn_numeric:#{isbn} AND +press_sim:barpublishing", rows: 100_000)

      if docs.count > 1 # shouldn't happen
        puts "More than 1 Monograph found using ISBN in #{bar_file.basename} ... SKIPPING ROW"
        docs.each { |doc| puts Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id) }
        puts
        next
      end

      if docs.count == 0
        puts "No Monograph found using ISBN in #{bar_file.basename} ... SKIPPING"
        next
      end

      puts "1 Monograph found using ISBN in #{bar_file.basename} ... CHECKING FILES"
      doc = docs.first

      if bar_file.to_s.ends_with?('.png')
        if doc['representative_id_ssim'].blank?
          puts "    No cover found. Adding cover using #{bar_file}"
          Tmm::FileService.add(doc: doc, file: bar_file, kind: :cover)
        else
          if Tmm::FileService.replace?(file_set_id: doc['representative_id_ssim'].first, new_file_path: bar_file)
             puts "    Current cover will be replaced with new #{bar_file}"
             Tmm::FileService.replace(file_set_id: doc['representative_id_ssim'].first, new_file_path: bar_file)
          end
        end
      end

      if bar_file.to_s.ends_with?('.pdf')
        file_set_id = FeaturedRepresentative.where(work_id: doc.id, kind: 'pdf_ebook').first&.file_set_id

        if file_set_id.blank?
          puts "    No pdf_ebook found. Adding pdf_ebook using #{bar_file}"
          Tmm::FileService.add(doc: doc, file: bar_file, kind: :pdf)

        elsif Tmm::FileService.replace?(file_set_id: file_set_id, new_file_path: bar_file)
          puts "    Current pdf will be replaced with new #{bar_file}"
          Tmm::FileService.replace(file_set_id: file_set_id, new_file_path: bar_file)
        end
      end
    end
  end
end
