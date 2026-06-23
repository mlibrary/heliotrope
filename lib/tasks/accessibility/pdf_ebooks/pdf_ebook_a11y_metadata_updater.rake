# frozen_string_literal: true

# rubocop:disable Metrics/BlockLength

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Check pdf_ebook representatives for missing or stale accessibility JSON files, clean up orphaned JSONs, and reindex Monographs whose JSON was recently updated'
namespace :heliotrope do
  task :pdf_ebook_a11y_metadata_updater,
       [:json_parent_dir, :pdf_output_dir, :dry_run, :reader_only_pdfs, :reindex_window_in_hours] => :environment do |_t, args|
    # Normal usage:
    # bundle exec rails "heliotrope:pdf_ebook_a11y_metadata_updater[/path/to/json_parent_dir,/path/to/pdf_output_dir]"
    #
    # With all options:
    # bundle exec rails "heliotrope:pdf_ebook_a11y_metadata_updater[/path/to/json_parent_dir,/path/to/pdf_output_dir,false,true,24]"
    #
    # Dry run (no files written, deleted, or Monographs reindexed):
    # bundle exec rails "heliotrope:pdf_ebook_a11y_metadata_updater[/path/to/json_parent_dir,/path/to/pdf_output_dir,true]"

    json_parent_dir = args.json_parent_dir
    pdf_output_dir = args.pdf_output_dir
    dry_run = args.dry_run&.to_s&.downcase != 'false'
    reader_only_pdfs = args.reader_only_pdfs&.to_s&.downcase != 'false'
    reindex_window_in_hours = (args.reindex_window_in_hours || 24).to_i

    puts "DRY RUN - no files will be written, deleted, or Monographs reindexed" if dry_run

    ##############################################################
    # Validate directories
    ##############################################################

    unless Dir.exist?(json_parent_dir)
      fail "json_parent_dir does not exist: #{json_parent_dir}"
    end

    unless File.writable?(json_parent_dir)
      fail "json_parent_dir is not writable: #{json_parent_dir}"
    end

    unless Dir.exist?(pdf_output_dir)
      fail "pdf_output_dir does not exist: #{pdf_output_dir}"
    end

    unless File.writable?(pdf_output_dir)
      fail "pdf_output_dir is not writable: #{pdf_output_dir}"
    end

    ##############################################################
    # Step 1 — find PDFs whose JSON is missing or out of date
    ##############################################################

    # Build a work_id => file_set_id map for all pdf_ebook FeaturedRepresentatives
    pdf_ebook_frs = FeaturedRepresentative.where(kind: 'pdf_ebook')
    work_id_to_file_set_id = pdf_ebook_frs.each_with_object({}) do |fr, hash|
      hash[fr.work_id] = fr.file_set_id
    end

    if reader_only_pdfs
      epub_monograph_ids = FeaturedRepresentative.where(kind: 'epub').map(&:work_id)
    end

    # expected_json_filenames_per_press is used later by Step 2 to detect orphaned JSON files.
    # Structure: { "michigan" => ["abc123def456.json", ...], ... }  (keyed by MD5 checksum)
    expected_json_filenames_per_press = Hash.new { |h, k| h[k] = [] }

    pdfs_written_count = 0

    work_id_to_file_set_id.each do |work_id, file_set_id|
      # Fetch the Monograph Solr document to get press subdomain and reader format
      monograph_docs = ActiveFedora::SolrService.query(
        "+has_model_ssim:Monograph AND +id:#{work_id}",
        fl: %w[id press_tesim],
        rows: 1
      )
      monograph_doc = monograph_docs&.first
      next if monograph_doc.nil?

      press = monograph_doc['press_tesim']&.first
      next if press.blank?

      # Fetch the pdf_ebook FileSet Solr document
      file_set_docs = ActiveFedora::SolrService.query(
        "+has_model_ssim:FileSet AND +id:#{file_set_id}",
        fl: %w[id original_checksum_ssim],
        rows: 1
      )
      file_set_doc = file_set_docs&.first
      next if file_set_doc.nil?

      # original_checksum_ssim is multivalued in Solr. Strip any "urn:md5:" prefix just in case,
      # though in practice FileSetIndexer indexes the plain hex MD5 string from FITS characterization.
      # There should be exactly *one* value in this multi-valued Solr field, re-characterize otherwise and skip
      solr_checksums = file_set_doc['original_checksum_ssim']
      if solr_checksums&.first&.blank? || solr_checksums&.count != 1
        if solr_checksums&.first&.blank?
          puts "No Solr checksum for FileSet #{file_set_id} — calling CharacterizeJob and skipping"
        elsif solr_checksums&.count != 1
          puts "Multiple Solr checksums for FileSet #{file_set_id} — calling CharacterizeJob and skipping" if solr_checksums&.count != 1
        end
        f = FileSet.find(file_set_id)
        CharacterizeJob.perform_later(f, f.original_file.id, nil)
        next
      end
      solr_checksum = solr_checksums.first
      solr_md5 = solr_checksum.sub(/\Aurn:md5:/i, '')

      # checksum-based JSON filename — allows for multiple FileSets with the same checksum to be processed
      # (e.g. if the same PDF is used for multiple EPUBs). This happens quite a bit with draft/published duplicates etc
      json_filename = "#{solr_md5}.json"

      expected_json_filenames_per_press[press] << json_filename

      press_json_dir = File.join(json_parent_dir, press)

      # we still need the filename added to the list of expected JSON filenames for Step 2, even if the reader format is not PDF,
      # because we want to delete orphaned JSON files for non-PDF reader format FileSets as well, but this is as far as we need to go
      if reader_only_pdfs
        next if epub_monograph_ids.include?(work_id)
      end

      json_filepath = File.join(press_json_dir, json_filename)

      needs_updating = false

      if !File.exist?(json_filepath)
        puts "JSON missing for #{file_set_id} (#{press}/#{json_filename})"
        needs_updating = true
      else
        begin
          json_data = JSON.parse(File.read(json_filepath))
          json_md5 = json_data['md5']

          if json_md5 != solr_md5
            puts "Checksum mismatch for #{file_set_id} (JSON: #{json_md5}, Solr: #{solr_md5}) — marking for update (and re-characterizing, just in case)"
            needs_updating = true

            f = FileSet.find(file_set_id)
            CharacterizeJob.perform_later(f, f.original_file.id, nil)
          end
        rescue JSON::ParserError => e
          puts "Could not parse #{json_filepath}: #{e.message} — marking for update"
          needs_updating = true
        end
      end

      next unless needs_updating

      # Stream the PDF to pdf_output_dir/<press>/<solr_md5>.pdf for external processing
      press_pdf_output_dir = File.join(pdf_output_dir, press)
      pdf_output_path = File.join(press_pdf_output_dir, "#{solr_md5}.pdf")

      if dry_run
        puts "[DRY RUN] Would write PDF to #{pdf_output_path}"
        pdfs_written_count += 1
      else
        begin
          FileUtils.mkdir_p(press_pdf_output_dir) unless Dir.exist?(press_pdf_output_dir)
          file_set = FileSet.find(file_set_id)
          File.open(pdf_output_path, 'wb') do |dest|
            file_set.original_file.stream.each { |chunk| dest.write(chunk) }
          end
          puts "Wrote PDF to #{pdf_output_path}"
          pdfs_written_count += 1
        rescue Ldp::Gone
          puts "FileSet #{file_set_id} is gone (Ldp::Gone) — skipping"
        rescue StandardError => e
          puts "Error writing PDF #{pdf_output_path}: #{e.message}"
        end
      end
    end

    puts "Step 1 complete: #{dry_run ? '[DRY RUN] would have written' : 'wrote'} #{pdfs_written_count} PDF(s) for external processing"

    ##############################################################
    # Step 2 — delete orphaned JSON files
    ##############################################################

    orphaned_count = 0

    Dir.glob(File.join(json_parent_dir, '**', '*.json')).each do |json_file|
      press = File.basename(File.dirname(json_file))
      filename = File.basename(json_file)

      next if expected_json_filenames_per_press[press]&.include?(filename)

      if dry_run
        puts "[DRY RUN] Would delete orphaned JSON: #{json_file}"
      else
        puts "Deleting orphaned JSON: #{json_file}"
        File.delete(json_file)
      end
      orphaned_count += 1
    end

    puts "Step 2 complete: #{dry_run ? '[DRY RUN] would have deleted' : 'deleted'} #{orphaned_count} orphaned JSON file(s)"

    ##############################################################
    # Step 3 — reindex Monographs whose JSON was recently updated
    ##############################################################

    reindex_cutoff = Time.zone.now - reindex_window_in_hours.hours
    reindexed_count = 0

    Dir.glob(File.join(json_parent_dir, '**', '*.json')).each do |json_file|
      next unless File.mtime(json_file) >= reindex_cutoff

      begin
        json_data = JSON.parse(File.read(json_file))
      rescue JSON::ParserError => e
        puts "Could not parse #{json_file}: #{e.message} — skipping reindex"
        next
      end

      json_md5 = json_data['md5']
      next if json_md5.blank?

      # Find the FileSet in Solr by checksum (plain MD5 hex string, as indexed by FileSetIndexer).
      file_set_results = ActiveFedora::SolrService.query(
        "+has_model_ssim:FileSet AND +original_checksum_ssim:\"#{json_md5}\"",
        fl: %w[id monograph_id_ssim],
        rows: 100
      )

      if file_set_results.blank?
        puts "No FileSet found in Solr for JSON md5 #{json_md5} (#{json_file}) — skipping reindex"
        next
      end

      monograph_ids = file_set_results.flat_map { |doc| doc['monograph_id_ssim'] }.compact.uniq

      monograph_ids.each do |monograph_id|
        if dry_run
          puts "[DRY RUN] Would reindex Monograph #{monograph_id} (triggered by #{File.basename(json_file)})"
        else
          puts "Reindexing Monograph #{monograph_id} (triggered by #{File.basename(json_file)})"
          UpdateIndexJob.perform_later(monograph_id)
        end
        reindexed_count += 1
      end

      # Delete the associated PDF that was written in Step 1 (the external Python app has now processed it)
      press = File.basename(File.dirname(json_file))
      pdf_label = File.basename(json_file).sub(/\.json\z/i, '.pdf')
      pdf_path = File.join(pdf_output_dir, press, pdf_label)

      if File.exist?(pdf_path)
        if dry_run
          puts "[DRY RUN] Would delete processed PDF: #{pdf_path}"
        else
          puts "Deleting processed PDF: #{pdf_path}"
          File.delete(pdf_path)
        end
      end
    end

    puts "Step 3 complete: #{dry_run ? '[DRY RUN] would have queued' : 'queued'} #{reindexed_count} Monograph reindex job(s)"
  end
end
# rubocop:enable Metrics/BlockLength
