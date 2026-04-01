# frozen_string_literal: true

desc 'Output specific fields for all BAR Monographs with separated ISBNs'
namespace :heliotrope do
  task :bar_monographs_report_with_separated_isbns, [:directory] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:bar_monographs_report_with_separated_isbns[/a_writable_folder]"

    if !File.writable?(args.directory)
      puts "Provided directory (#{args.directory}) is not writable. Exiting."
      exit
    end

    if Press.find_by(subdomain: 'barpublishing').blank?
      puts "Subdomain (barpublishing) does not exist. Exiting."
      exit
    end

    file_path = File.join(args.directory, "barpublishing_monographs_report_with_separated_isbns_#{Time.now.getlocal.strftime("%Y-%m-%d")}.csv")

    docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND +press_sim:barpublishing", rows: 100_000)

    CSV.open(file_path, "w") do |csv|
      csv << ["Monograph Title/Link", "BAR Number", "Author", "print ISBN", "ebook ISBN", "Published?", "Tombstoned?"]
      docs.each_with_index do |doc, index|
      isbns = doc['isbn_tesim']&.map(&:strip)&.reject(&:blank?) || []

      csv << ["=HYPERLINK(\"#{Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id)}\", \"#{doc['title_tesim']&.first&.gsub('"', '""')}\")",
              bar_number_for_bar_monographs_report_with_separated_isbns(doc),
              doc['creator_tesim']&.first&.gsub('"', '""'),
              print_isbn(isbns),
              online_isbn(isbns),
              doc['visibility_ssi'] == 'open' ? 'YES' : 'NO',
              doc['tombstone_ssim']&.first == 'yes' ? 'YES' : 'NO']
      end
    end

    puts "BAR Monograph report with separated ISBNs saved to #{file_path}"
  end
end


def bar_number_for_bar_monographs_report_with_separated_isbns(doc)
  doc['identifier_tesim']&.find { |i| i[/^bar_number:.*/] }&.gsub('bar_number:', '')&.strip
end
