# frozen_string_literal: true

desc 'Output A List of Download-Only Ebooks (For Accessibility Remediation) for all Monographs in a Press'
namespace :heliotrope do
  task :resource_file_sets_accessibility_remediation_report_by_press, [:directory, :subdomain] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:resource_file_sets_accessibility_remediation_report_by_press[/a_writable_folder, subdomain]"
    # Usage for all Monographs: bundle exec rails "heliotrope:resource_file_sets_accessibility_remediation_report_by_press[/a_writable_folder, all_presses]"

    if !File.writable?(args.directory)
      puts "Provided directory (#{args.directory}) is not writable. Exiting."
      exit
    end

    if args.subdomain != 'all_presses' && Press.find_by(subdomain: args.subdomain).blank?
      puts "Provided subdomain (#{args.subdomain}) does not exist. Exiting."
      exit
    end

    file_path = File.join(args.directory, "#{args.subdomain}_resource_file_sets_accessibility_remediation_report_#{Time.now.getlocal.strftime("%Y-%m-%d")}.csv")

    solr_query = if args.subdomain == 'all_presses'
                   "+has_model_ssim:Monograph"
                 else
                   "+has_model_ssim:Monograph AND +press_sim:#{args.subdomain}"
                 end

    docs = ActiveFedora::SolrService.query(solr_query, fl: ['id', 'press_tesim', 'title_tesim'], rows: 100_000)

    resource_file_set_ids = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND -hidden_representative_bsi:true", fl: [:id], rows: 100_000).map(&:id)

    fail "No resource file sets found. Exiting." if resource_file_set_ids.blank?

    query  = "SELECT noid, COUNT(*) as hits " \
      "FROM counter_reports " \
      "WHERE section_type IS NULL AND "

    query += "press = (SELECT id FROM presses WHERE subdomain = '#{args.subdomain}') AND " if args.subdomain != 'all_presses'

    # note that we don't need to address EPUBs in this report, as they always defer to being the reader ebook, and therefore they are present in the reader ebook remediation report
    query += "model='FileSet' AND parent_noid IS NOT NULL " \
      "AND noid IN ('#{resource_file_set_ids.join("','")}') " \
      "GROUP BY noid " \
      "ORDER BY hits DESC"

    result = ActiveRecord::Base.connection.exec_query(query)
    resource_file_set_noid_lookup = {}
    result.rows.each { |row| resource_file_set_noid_lookup[row[0]] = row[1] }

    CSV.open(file_path, "w") do |csv|
      docs.each_with_index do |doc, index|
        press = Press.find_by(subdomain: doc['press_tesim'])
        top_level_press = press.parent_id.present? ? Press.find(press.parent_id).subdomain : press.subdomain

        resource_file_set_docs = ActiveFedora::SolrService.query("+has_model_ssim:FileSet AND monograph_id_ssim:#{doc.id} AND -hidden_representative_bsi:true",
                                                                 fl: [:id, :label_tesim, :title_tesim, :visibility_ssi, :closed_captions_tesim, :visual_descriptions_tesim,
                                                                      :page_count_tesim, :resource_type_tesim, :alt_text_tesim, :external_resource_url_ssim, :allow_download_ssim],
                                                                 rows: 100_000)

        if index == 0
          csv << (['Top-Level Press', 'Press', 'Monograph NOID', 'Monograph Title/Link', 'FileSet NOID', 'FileSet Title/Link', 'File Name/Download Link',
                   'File Extension', 'Page Count (if applicable)', 'External Resource URL', 'Resource Type', 'Alt Text', 'Closed Captions Present?', 'Closed Captions Link',
                   'Visual Descriptions Present?', 'Visual Descriptions Link', 'Allow Download?', 'Published?', 'Hits'])
        end

        resource_file_set_docs.each_with_index do |resource_file_set_doc, index|
          extension = File.extname(resource_file_set_doc['label_tesim']&.first).delete('.').upcase if resource_file_set_doc['label_tesim']&.first.present?
          published = resource_file_set_doc['visibility_ssi'] == 'open' ? 'TRUE' : 'FALSE'

          closed_captions_present = resource_file_set_doc['closed_captions_tesim'].present? ? 'TRUE' : 'FALSE'
          closed_captions_link = if resource_file_set_doc['closed_captions_tesim'].present?
                                   Hyrax::Engine.routes.url_helpers.download_url(resource_file_set_doc.id, file: 'captions_vtt', host: 'www.fulcrum.org', protocol: 'https')
                                 else
                                   nil
                                 end

          visual_descriptions_present = resource_file_set_doc['visual_descriptions_tesim'].present? ? 'TRUE' : 'FALSE'
          visual_descriptions_link = if resource_file_set_doc['visual_descriptions_tesim'].present?
                                       Hyrax::Engine.routes.url_helpers.download_url(resource_file_set_doc.id, file: 'descriptions_vtt', host: 'www.fulcrum.org', protocol: 'https')
                                     else
                                       nil
                                     end

          csv << [top_level_press,
                  press.subdomain,
                  "'" + doc.id,
                  "=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id)}\",\"#{doc['title_tesim']&.first&.gsub('"', '""')}\")",
                  "'" + resource_file_set_doc.id,
                  "=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_file_set_url(resource_file_set_doc.id)}\", \"#{resource_file_set_doc['title_tesim']&.first&.gsub('"', '""')}\")",
                  "=HYPERLINK(\"#{Hyrax::Engine.routes.url_helpers.download_url(resource_file_set_doc.id, host: 'www.fulcrum.org', protocol: 'https')}\", \"#{resource_file_set_doc['label_tesim']&.first&.gsub('"', '""')}\")",
                  extension,
                  resource_file_set_doc['page_count_tesim']&.first,
                  resource_file_set_doc['external_resource_url_ssim']&.first,
                  resource_file_set_doc['resource_type_tesim']&.first,
                  resource_file_set_doc['alt_text_tesim']&.first,
                  closed_captions_present,
                  closed_captions_link,
                  visual_descriptions_present,
                  visual_descriptions_link,
                  resource_file_set_doc['allow_download_ssim']&.first,
                  published,
                  resource_file_set_noid_lookup[resource_file_set_doc.id]]
        end
      end
    end
    puts "Resource FileSet accessibility remediation data for press '#{args.subdomain}' saved to #{file_path}"
  end
end
