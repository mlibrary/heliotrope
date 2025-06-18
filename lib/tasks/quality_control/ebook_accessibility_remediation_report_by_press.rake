# frozen_string_literal: true

desc 'Output Ebook Accessibility Metadata for all Monographs in a Press'
namespace :heliotrope do
  task :ebook_accessibility_remediation_report_by_press, [:directory, :subdomain] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:ebook_accessibility_remediation_report_by_press[/a_writable_folder, subdomain]"
    # Usage for all Monographs: bundle exec rails "heliotrope:ebook_accessibility_remediation_report_by_press[/a_writable_folder, all_presses]"

    if !File.writable?(args.directory)
      puts "Provided directory (#{args.directory}) is not writable. Exiting."
      exit
    end

    if args.subdomain != 'all_presses' && Press.find_by(subdomain: args.subdomain).blank?
      puts "Provided subdomain (#{args.subdomain}) does not exist. Exiting."
      exit
    end

    file_path = File.join(args.directory, "#{args.subdomain}_ebook_accessibility_remediation_report_#{Time.now.getlocal.strftime("%Y-%m-%d")}.csv")

    solr_query = if args.subdomain == 'all_presses'
                   "+has_model_ssim:Monograph"
                 else
                   "+has_model_ssim:Monograph AND +press_sim:#{args.subdomain}"
                 end

    docs = ActiveFedora::SolrService.query(solr_query, fl: ['id', 'epub_version_ssi', 'epub_a11y_accessibility_summary_ssi', 'epub_a11y_accessibility_feature_ssim', 'epub_a11y_accessibility_hazard_ssim', 'epub_a11y_access_mode_ssim', 'epub_a11y_access_mode_sufficient_ssim', 'epub_a11y_screen_reader_friendly_ssi', 'epub_a11y_conforms_to_ssi', 'epub_a11y_certifier_credential_ssi', 'epub_a11y_certifier_credential_ssi'], rows: 100_000)

    query  = "SELECT parent_noid, COUNT(*) as hits " \
             "FROM counter_reports " \
             "WHERE "

    query += "press = (SELECT id FROM presses WHERE subdomain = '#{args.subdomain}') AND " if args.subdomain != 'all_presses'

    query += "model='FileSet' AND parent_noid IS NOT NULL " \
               "AND noid IN (SELECT DISTINCT file_set_id from featured_representatives WHERE kind IN ('epub', 'pdf_ebook')) " \
             "GROUP BY parent_noid " \
             "ORDER BY hits DESC"

    result = ActiveRecord::Base.connection.exec_query(query)
    mono_noid_lookup = {}
    result.rows.each { |row| mono_noid_lookup[row[0]] = row[1] }

    CSV.open(file_path, "w") do |csv|
      docs.each_with_index do |doc, index|
        featured_representative_kinds = FeaturedRepresentative.where(work_id: doc.id, kind: ['audiobook', 'epub', 'pdf_ebook', 'mobi']).map { |fr| fr.kind.upcase.gsub('PDF_EBOOK', 'PDF') }.sort.join('; ')
        featured_representative_ereader = if featured_representative_kinds.include? 'EPUB'
                                            'EPUB'
                                          elsif featured_representative_kinds.include? 'PDF'
                                            'PDF'
                                          end

        a11y_metadata = [doc['epub_a11y_screen_reader_friendly_ssi'], doc['epub_version_ssi'], doc['epub_a11y_accessibility_summary_ssi'], doc['epub_a11y_accessibility_feature_ssim']&.join('; '), doc['epub_a11y_accessibility_hazard_ssim']&.join('; '), doc['epub_a11y_access_mode_ssim']&.join('; '), doc['epub_a11y_access_mode_sufficient_ssim']&.join('; '), doc['epub_a11y_conforms_to_ssi'], doc['epub_a11y_certified_by_ssi'], doc['epub_a11y_certifier_credential_ssi']]

        exporter = Export::Exporter.new(doc.id, :monograph)

        if index == 0
          exporter_header = []
          fr_headers = ['Fulcrum Reader Ebook Format', 'All Ebook Formats']
          a11y_metadata_headers = ['Screen Reader Friendly', 'EPUB Version', 'Accessibility Summary', 'Accessibility Features', 'Accessibility Hazards', 'Access Modes Sufficient', 'Access Modes', 'Accessibility Conformance', 'Certified By', 'Certifier Credential']
          exporter.write_csv_header_rows(exporter_header)
          # we only want the actual exporter headers, not the second row of metadata instructions
          csv << (exporter_header[0] + fr_headers + a11y_metadata_headers + ['Hits'])
        end

        csv << (exporter.monograph_row + [featured_representative_ereader, featured_representative_kinds] + a11y_metadata + [mono_noid_lookup[doc.id]])
      end
    end

    puts "Ebook accessibility remediation data for press '#{args.subdomain}' saved to #{file_path}"
  end
end
