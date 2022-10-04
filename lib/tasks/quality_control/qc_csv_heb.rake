# frozen_string_literal: true

desc 'Output CSV file (for QC Google Sheet) for HEB Monographs ingested since a given DateTime, visibility optional'
namespace :heliotrope do
  task :qc_csv_heb, [:datetime, :visibility] => :environment do |_t, args|
    # Usage: Needs a valid datetime as a parameter
    # $ bundle exec rails "heliotrope:qc_csv_heb[2018-06-08T00:00:00-05:00]"

    begin
      start_time = Time.zone.parse(args.datetime)
    rescue ArgumentError
      puts "You must provide a valid DateTime string as seen here: heliotrope:qc_csv_heb[2018-06-08T00:00:00-04:00]"
      exit
    end
    start_time_solr = start_time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')

    filename = '/tmp/heliotrope_heb_qc_from_' + start_time.iso8601 + '_to_' + Time.now.iso8601 + '.csv'
    line_count = 0
    query_string = '+has_model_ssim:Monograph AND +press_sim:heb'
    query_string += args.visibility.blank? ? '' : " AND +visibility_ssi:#{args.visibility}"

    docs = ActiveFedora::SolrService.query(query_string, fq: "date_uploaded_dtsi:[#{start_time_solr} TO NOW]",
                                           fl: ['id', 'identifier_tesim', 'title_tesim', 'date_uploaded_dtsi', 'visibility_ssi'],
                                           sort: 'date_uploaded_dtsi asc',
                                           rows: 100_000)

    puts "#{docs.count} Solr docs found."

    CSV.open(filename, "w") do |csv|
      # header row
      csv << ['Monograph Visibility', 'HEB ID', 'Monograph Link', 'Monograph Upload Date', 'EPUB Upload Date (latest version)']

      docs.each_with_index do |doc, index|
        puts "Processing document #{index + 1} of #{docs.count}"

        epub_id = FeaturedRepresentative.where(work_id: doc.id, kind: 'epub')&.first&.file_set_id
        next if epub_id.blank?

        epub_upload_time = begin
                             FileSet.find(epub_id)&.original_file&.versions&.all&.map(&:created)&.sort&.last
                           rescue Ldp::Gone
                             nil
                           end

        # note the time here has milliseconds (%L) where `doc['date_uploaded_dtsi']` below does not but, as described...
        # in HELIO-2167, the millisecond value is dropped for even seconds so use Time.parse(), not Time.strptime()
        epub_upload_time = epub_upload_time.present? ? Time.zone.parse(epub_upload_time).strftime('%Y-%m-%d') : ''

        csv << [doc['visibility_ssi'], doc['identifier_tesim']&.find { |i| i.strip.downcase[/^heb_id:\s*heb[0-9]{5}/] }&.strip&.downcase&.gsub(/heb_id:\s*/, ''),
                '=HYPERLINK("' + Rails.application.routes.url_helpers.hyrax_monograph_url(doc.id) + '","' + doc['title_tesim'].first.gsub('"', '""') + '")',
                Time.zone.parse(doc['date_uploaded_dtsi']).strftime('%Y-%m-%d'), epub_upload_time]
        line_count += 1
      end
    end
    puts 'Output (' + line_count.to_s + ' lines) written to ' + filename
  end
end
