# frozen_string_literal: true

desc 'Output A List of Download-Only Ebooks (For Accessibility Remediation) for all Monographs in a Press'
namespace :heliotrope do
  task :download_only_ebook_accessibility_remediation_report_by_press, [:directory, :subdomain] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:download_only_ebook_accessibility_remediation_report_by_press[/a_writable_folder, subdomain]"
    # Usage for all Monographs: bundle exec rails "heliotrope:download_only_ebook_accessibility_remediation_report_by_press[/a_writable_folder, all_presses]"

    if !File.writable?(args.directory)
      puts "Provided directory (#{args.directory}) is not writable. Exiting."
      exit
    end

    if args.subdomain != 'all_presses' && Press.find_by(subdomain: args.subdomain).blank?
      puts "Provided subdomain (#{args.subdomain}) does not exist. Exiting."
      exit
    end

    file_path = File.join(args.directory, "#{args.subdomain}_download_only_ebook_accessibility_remediation_report_#{Time.now.getlocal.strftime("%Y-%m-%d")}.csv")

    solr_query = if args.subdomain == 'all_presses'
                   "+has_model_ssim:Monograph"
                 else
                   "+has_model_ssim:Monograph AND +press_sim:#{args.subdomain}"
                 end

    docs = ActiveFedora::SolrService.query(solr_query, fl: ['id', 'press_tesim', 'title_tesim'], rows: 100_000)

    query  = "SELECT noid, COUNT(*) as hits " \
             "FROM counter_reports " \
             "WHERE section_type IS NULL AND "

    query += "press = (SELECT id FROM presses WHERE subdomain = '#{args.subdomain}') AND " if args.subdomain != 'all_presses'

    # note that we don't need to address EPUBs in this report, as they always defer to being the reader ebook, and therefore they are present in the reader ebook remediation report
    query += "model='FileSet' AND parent_noid IS NOT NULL " \
               "AND noid IN (SELECT DISTINCT file_set_id from featured_representatives WHERE kind IN ('audiobook', 'mobi', 'pdf_ebook')) " \
             "GROUP BY noid " \
             "ORDER BY hits DESC"

    result = ActiveRecord::Base.connection.exec_query(query)
    ebook_noid_lookup = {}
    result.rows.each { |row| ebook_noid_lookup[row[0]] = row[1] }

    CSV.open(file_path, "w") do |csv|
      docs.each_with_index do |doc, index|
        press = Press.find_by(subdomain: doc['press_tesim'])
        top_level_press = press.parent_id.present? ? Press.find(press.parent_id).subdomain : press.subdomain

        featured_representatives = FeaturedRepresentative.where(work_id: doc.id, kind: ['audiobook', 'epub', 'pdf_ebook', 'mobi']).to_a

        featured_representatives.reject! do |fr|
          fr.kind == 'pdf_ebook' && featured_representatives.none? { |fr| fr.kind == 'epub' }
        end
        featured_representatives.reject! { |fr| fr.kind == 'epub' }
        fr_ids = featured_representatives.map(&:file_set_id)
        fr_kinds = featured_representatives.map(&:kind)

        fr_docs = ActiveFedora::SolrService.query("{!terms f=id}#{fr_ids.join(',')}", fl: ['id', 'label_tesim', 'allow_download_ssim'], rows: 10_000)

        if index == 0
          csv << (['Top-Level Press', 'Press', 'Monograph NOID', 'Monograph Title/Link', 'Ebook NOID', 'Ebook Title/Link', 'Ebook Format', 'Ebook Filename/Download Link', 'Hits'])
        end

        fr_docs.each_with_index do |fr_doc, index|
          next unless fr_doc['allow_download_ssim']&.first&.downcase == 'yes'

          kind = fr_kinds[index].gsub('_ebook', '').upcase

          csv << [top_level_press,
                  press.subdomain,
                  "'" + doc.id,
                  "=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id)}\",\"#{doc['title_tesim']&.first.gsub('"', '""')}\")",
                  "'" + fr_doc.id,
                  "=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_file_set_url(fr_doc.id)}\", \"#{fr_doc['label_tesim']&.first.gsub('"', '""')}\")",
                  kind,
                  "=HYPERLINK(\"#{Hyrax::Engine.routes.url_helpers.download_url(fr_doc.id, host: 'www.fulcrum.org', protocol: 'https')}\", \"#{fr_doc['label_tesim']&.first.gsub('"', '""')}\")",
                  ebook_noid_lookup[fr_doc.id]]
        end
      end
    end
    puts "Download-only ebook accessibility remediation data for press '#{args.subdomain}' saved to #{file_path}"
  end
end
