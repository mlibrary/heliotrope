# frozen_string_literal: true

desc 'Output CSV file (for QC Google Sheet) for draft Michigan Monographs ingested since a given DateTime'
namespace :heliotrope do
  task :qc_csv_michigan, [:datetime] => :environment do |_t, args|
    # Usage: Needs a valid datetime as a parameter
    # $ bundle exec rake "heliotrope:qc_csv_michigan[2018-06-08T00:00:00-05:00]"

    begin
      start_time = DateTime.strptime(args.datetime, '%Y-%m-%dT%H:%M:%S%z')
    rescue ArgumentError
      puts "You must provide a valid DateTime string as seen here: heliotrope:qc_csv_michigan[2018-06-08T00:00:00-04:00]"
      exit
    end
    start_time_solr = start_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

    filename = '/tmp/heliotrope_michigan_qc_from_' + start_time.iso8601 + '_to_' + DateTime.now.iso8601 + '.csv'
    line_count = 0

    docs = ActiveFedora::SolrService.query('+has_model_ssim:Monograph AND +press_sim:michigan AND +visibility_ssi:restricted',
                                           fq: "date_uploaded_dtsi:[#{start_time_solr} TO NOW]",
                                           fl: ['id', 'isbn_tesim', 'title_tesim', 'date_uploaded_dtsi'],
                                           sort: 'date_uploaded_dtsi asc',
                                           rows: 100000)

    CSV.open(filename, "w") do |csv|
      docs.each do |doc|

        ebook_isbn = ''
        doc['isbn_tesim']&.each do |isbn|
          isbn = isbn.gsub('-', '').downcase
          ebook_isbn = isbn.sub(/\s*\(.+\)$/, '').strip if isbn[/\(([^()]*)\)/]&.gsub(/\(|\)/, '')&.strip == 'ebook'
        end

        # right now we expect all Michigan EPUBS (e.g. EBC) to be entered with an (e-book) ISBN
        if ebook_isbn.blank?
          puts "WARNING! Monograph #{doc.id} has no detectable e-book ISBN ...... SKIPPING!"
          next
        end

        csv << [ebook_isbn,
                '=HYPERLINK("' + Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id) + '","' + doc['title_tesim'].first.gsub('"', '""') + '")',
                Time.strptime(doc['date_uploaded_dtsi'], '%Y-%m-%dT%H:%M:%S%z').strftime('%Y-%m-%d')]
        line_count += 1
      end
    end
    puts 'Output (' + line_count.to_s + ' lines) written to ' + filename
  end
end
