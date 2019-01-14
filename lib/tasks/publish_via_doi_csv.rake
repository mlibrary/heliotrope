# frozen_string_literal: true

desc 'Use a CSV whose *first column* holds DOIs to identify and publish Monographs'

namespace :heliotrope do
  task :publish_via_doi_csv, [:publisher, :input_file] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:publish_via_doi_csv[/path/to/subject/input_file.csv]"
    fail "CSV file not found: #{args.input_file}" unless File.exist?(args.input_file)

    published_count = 0
    rows = CSV.read(args.input_file, skip_blanks: true).delete_if { |row| row.all?(&:blank?) }

    rows.each do |row|
      # We only store the DOI part in Fulcrum, chop up full URL if that's what we have
      doi = row[0].sub('https', 'http').sub('http://doi.org/', '')
      matches = Monograph.where(press_sim: args.publisher, doi_ssim: doi)

      if matches.count.zero?
        puts 'No Monograph found with DOI "' + doi + '"............... SKIPPING'
      elsif matches.count > 1
        puts 'More than 1 Monograph found with DOI "' + doi + '"...... SKIPPING'
      else
        published_count += 1
        puts '1 Monograph found with DOI "' + doi + '" ...... SENDING TO PUBLISHJOB'

        m = matches.first
        PublishJob.perform_later(m)
      end
    end

    puts "\nDONE. " + published_count.to_s + ' Monographs were published.'
  end
end
