# frozen_string_literal: true

desc 'Output CSV file (for QC Google Sheet) for HEB Monographs ingested since a given DateTime'
namespace :heliotrope do
  task :heb_qc_csv, [:datetime] => :environment do |_t, args|
    # Usage: Needs a valid datetime as a parameter
    # $ bundle exec rake "heliotrope:heb_qc_csv[2018-06-08T00:00:00-04:00]"

    begin
      start_time = DateTime.strptime(args.datetime, '%Y-%m-%dT%H:%M:%S%z')
    rescue ArgumentError
      puts "You must provide a valid DateTime string as seen here: heliotrope:heb_qc_csv[2018-06-08T00:00:00-04:00]"
      exit
    end

    filename = '/tmp/heliotrope_heb_qc_from_' + start_time.iso8601 + '_to_' + DateTime.now.iso8601 + '.csv'
    line_count = 0

    CSV.open(filename, "w") do |csv|
      Monograph.all.to_a.each do |m|
        next unless m.press == 'heb' && m.date_uploaded > start_time

        csv << [m.identifier.find { |i| i[/^heb.*/] },
                '=HYPERLINK("' + Rails.application.routes.url_helpers.hyrax_monograph_url(m.id) + '","' + m.title.first.gsub('"', '""') + '")',
                m.date_uploaded.strftime('%Y-%m-%d')]
        line_count += 1
      end
    end
    puts 'Output (' + line_count.to_s + ' lines) written to ' + filename
  end
end
