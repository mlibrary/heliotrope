# frozen_string_literal: true

desc 'Task to be called by a cron to add resource FileSets to Monographs (ISBN lookup)'
namespace :heliotrope do
  task :tmm_non_representative_file_sets, [:publisher, :monograph_files_dir] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:tmm_non_representative_file_sets[michigan, /path/to/monographs_parent_dir]"

    # note: fail messages will be emailed to MAILTO by cron *unless* you use 2>&1 at the end of the job line
    fail "Monographs directory not found: '#{args.monograph_files_dir}'" unless Dir.exist?(args.monograph_files_dir)

    # need to ensure that we are finding Monographs from sub-presses (like gabii)
    all_presses = Press.where(parent: Press.where(subdomain: args.publisher).first).map(&:subdomain).push(args.publisher)
    all_presses = '("' + all_presses.join('" OR "') + '")'

    Pathname(args.monograph_files_dir).children.each do |mono_dir|
      next if !mono_dir.directory? || mono_dir.basename.to_s.start_with?('.')
      isbn = mono_dir.basename.to_s.sub(/\s*\(.+\)$/, '').delete('^0-9').strip
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


      resources_folder = Pathname.glob(mono_dir + 'resources', File::FNM_CASEFOLD)&.first
      if !resources_folder&.directory?
        puts "No resources directory found"
        next
      else
        puts "Looking for CSV and files in #{resources_folder.to_s}."
      end

      doc = docs.first

      # Right now I'm going with a one-off import when the Monograph has no resource files yet. Because the order...
      # of resource files matters and we have no way to control that if we add more files bit by bit.
      # If the Monograph has resources already, they will be checked to see if they should be replaced.
      mono_file_sets = doc[Solrizer.solr_name('ordered_member_ids', :symbol)]
      featured_reps = FeaturedRepresentative.where(work_id: doc.id)&.map(&:file_set_id)
      cover = doc['representative_id_ssim']&.first

      existing_resources = (Array(mono_file_sets) - Array(featured_reps)) - Array(cover)

      if existing_resources.count.zero?
        '  Monograph has no files. Attempting import.'
        importer = Import::Importer.new(root_dir: resources_folder.to_s, user_email: User.batch_user_key, monograph_id: doc.id,
                                        press: nil, visibility: nil, monograph_title: nil, quiet: true, workflow: nil)
        importer.run
      else
        '  Monograph has files. Comparing to files on disk.'
        # we're not looking in sub-directories of the resources folder here, so there's scope to make, e.g. a...
        # subfolder to archive previous versions of resource files. Note that technically the importer itself does...
        # look for files in sub-directories, possibly to allow for organizing "section" but we've never used that.
        file_paths = Pathname.glob(resources_folder + '*.*')
        file_paths.each do |file_path|
          file_doc = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND monograph_id_ssim:#{doc.id} AND +label_ssi:#{file_path.basename}", rows: 100_000)&.first
          next unless file_doc
          if Tmm::FileService.replace?(file_set_id: file_doc.id, new_file_path: file_path)
            puts "    FileSet #{file_doc.id}, '#{file_doc['label_ssi']}', will be replaced"
            Tmm::FileService.replace(file_set_id: file_doc.id, new_file_path: file_path)
          end
        end
      end
    end
  end
end
