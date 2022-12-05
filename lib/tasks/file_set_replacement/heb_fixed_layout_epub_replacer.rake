# frozen_string_literal: true

desc 'Add PDF FeaturedRepresentatives and unset the EPUB ones, also marking the latter as draft/no download'
namespace :heliotrope do
  task :replace_heb_fixed_layout_epubs, [:directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:replace_heb_fixed_layout_epubs[/mnt/umptmm/MPS/HEB/epub2pdf/Fulcrum_batch1/]"

    file_paths = Dir.glob(File.join(args.directory, '**/*.pdf')).sort

    file_paths.each do |fp|
      heb_id = File.basename(fp, '.pdf')
      monographs = ObjectLookupService.matches(heb_id)

      if monographs.count > 1
        puts "Multiple Monographs found using the HEB ID in the filename #{fp}!"
      elsif monographs.count == 0
        puts "No Monographs found using the HEB ID in the filename #{fp}!"
      else
        monograph = monographs.first
        puts "HEB ID in the filename #{fp} points to one Monograph with NOID #{monograph.id}. Proceeding..."

        pdf_file_set_id = FeaturedRepresentative.where(work_id: monograph.id, kind: 'pdf_ebook').first&.file_set_id

        if pdf_file_set_id.blank?
          puts "    No PDF representative found. Adding PDF representative using #{fp}"
          Tmm::FileService.add(doc: SolrDocument.new(id: monograph.id, depositor_tesim: ["fulcrum-system"]), file: fp, kind: :pdf, downloadable: false)
        else
          if Tmm::FileService.replace?(file_set_id: pdf_file_set_id, new_file_path: fp)
            puts "    Current PDF representative will be replaced with #{fp}"
            Tmm::FileService.replace(file_set_id: pdf_file_set_id, new_file_path: fp)
          else
            puts "    Current PDF representative found, but it is the same as #{fp}"
          end
        end

        epub_featured_representative = FeaturedRepresentative.where(work_id: monograph.id, kind: 'epub')&.first

        if epub_featured_representative.blank?
          puts "    No EPUB representative found."
        else
          puts "Found EPUB representative with NOID #{epub_featured_representative&.file_set_id}. Setting to draft, download == 'no' and and removing representative status"

          epub_file_set = FileSet.find(epub_featured_representative&.file_set_id)
          epub_file_set.visibility = 'restricted'
          epub_file_set.allow_download = 'no'
          epub_file_set.save

          epub_featured_representative.delete
        end
      end
    end
  end
end
