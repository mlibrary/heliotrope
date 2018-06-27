# frozen_string_literal: true

desc 'set subject for HEB Monographs from a CSV file'
namespace :heliotrope do
  task :heb_subject_metadata, [:input_file] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:heb_subject_metadata[/path/to/subject/input_file.csv]"
    fail "CSV file not found: #{args.input_file}" unless File.exist?(args.input_file)

    updated_count = 0
    rows = CSV.read(args.input_file, skip_blanks: true).delete_if { |row| row.all?(&:blank?) }

    # the current subject metadata Google Sheet has a header row when downloaded as CSV, remove it
    rows.shift

    rows.each do |row|
      matches = Monograph.where(identifier: row[0])

      if matches.count.zero?
        # NB: if we're running this before HEB ingest is finished then printing missing Monographs isn't useful
        puts 'No Monograph found with HEB ID "' + row[0] + '"............... SKIPPING'
      elsif matches.count > 1
        puts 'More than 1 Monograph found with HEB ID "' + row[0] + '"...... SKIPPING'
      else
        updated_count += 1
        puts '1 Monograph found with HEB ID "' + row[0] + '" setting subject to: "' + row[1] + '"'

        m = matches.first
        # subject is a multivalued field
        m.subject = Array.wrap(row[1])
        m.save!
      end
    end

    puts "\nDONE. " + updated_count.to_s + ' Monographs had their subject set.'
  end
end
