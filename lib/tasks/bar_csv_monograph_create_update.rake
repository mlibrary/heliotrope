# frozen_string_literal: true

# note: This is basically the lib/tasks/tmm/tmm_csv_monograph_create_update.rake script with the backup-Monographs-metadata-first stuff commented out

require 'htmlentities'
require 'csv'

desc 'Task to be called by a cron for Monographs create/edit from TMM CSV files (ISBN lookup)'
namespace :heliotrope do
  task :bar_csv_monograph_create_update, [:bar_csv_dir] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:bar_csv_monograph_create_update[/path/to/bar_csv_dir]"

    # note: fail messages will be emailed to MAILTO by cron *unless* you use 2>&1 at the end of the job line
    fail "CSV directory not found: '#{args.bar_csv_dir}'" unless Dir.exist?(args.bar_csv_dir)

    input_file = Dir.glob(File.join(args.bar_csv_dir, "ingest*#{Time.now.strftime('%Y%m%d')}.csv")).sort.last
    fail "CSV file not found in directory '#{args.bar_csv_dir}'" if input_file.blank?
    fail "CSV file may accidentally be a backup as '#{input_file}' contains 'bak'. Exiting." if input_file.include? 'bak'

    puts "Parsing file: #{input_file}"
    rows = CSV.read(input_file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    monograph_fields = METADATA_FIELDS.select { |f| %i[universal monograph].include? f[:object] }

    check_for_unexpected_columns_isbn(rows, monograph_fields)

    row_num = 1

    backup_file = ''
    backup_file_created = false

    # used to enable deletion of existing values
    blank_metadata = monograph_fields.pluck(:metadata_name).map { |name| [name, nil] }.to_h

    rows.each do |row|
      row_num += 1
      clean_isbns = []

      # ISBN(s) is a multi-valued field with entries separated by a ';'
      row['ISBN(s)']&.split(';')&.map(&:strip)&.each do |isbn|
        isbn = isbn.gsub('-', '').downcase
        clean_isbns << isbn.sub(/\s*\(.+\)$/, '').delete('^0-9').strip
      end

      # sometimes ISBNs come in as just a format, with no actual number, like `(Paper)`, so at this point they're blank
      clean_isbns = clean_isbns.reject(&:blank?)

      if clean_isbns.blank?
        puts "ISBN numbers missing on row #{row_num} ...................... SKIPPING ROW"
        next
      else
        matches = Monograph.where(press_sim: 'barpublishing', isbn_numeric: clean_isbns) #, visibility_ssi: 'restricted')

        if matches.count > 1 # shouldn't happen
          puts "More than 1 Monograph found using ISBN(s) #{clean_isbns.join('; ')} on row #{row_num} ... SKIPPING ROW"
          matches.each { |m| puts Rails.application.routes.url_helpers.hyrax_monograph_url(m.id) }
          puts
          next
        else
          new_monograph = matches.count.zero?
          monograph = new_monograph ? Monograph.new : matches.first

          current_ability = Ability.new(User.batch_user)

          attrs = {}
          Import::RowData.new.field_values(:monograph, row, attrs)
          attrs['press'] = 'barpublishing'

          # put both DOI and prefixed BAR Number in `identifier` field for now, leaving the not-yet-created DOI's out of it
          doi = attrs.delete('doi')
          bar_number = row['BAR Number']
          identifier = []
          identifier << doi unless doi.blank?
          identifier << 'bar_number: ' + bar_number unless bar_number.blank?
          identifier.present? ? attrs['identifier'] = identifier : attrs.delete('identifier')

          # blank Monograph titles caused problems. We don't allow them in the importer and shouldn't here either.
          if attrs['title'].blank?
            puts "Monograph title is blank on row #{row_num} ............ SKIPPING ROW"
            next
          end

          # in order to offer the ability to blank out metadata we need to merge in some nils
          attrs = blank_metadata.merge(attrs)

          # TMM has some fields with HTML tags in it. This functionality will have to be manually tested as...
          # part of HELIO-2298
          attrs = maybe_convert_to_markdown(attrs)

          # sending new_monograph param here because of a weird FCREPO bug that affects Hyrax work *creation* only
          # https://github.com/samvera/hyrax/issues/3527
          attrs = cleanup_characters(attrs, new_monograph)

          if new_monograph
            puts "No Monograph found using ISBN(s) '#{clean_isbns.join('; ')}' on row #{row_num} .......... CREATING"
            attrs['visibility'] = 'restricted'

            # Hyrax::CurationConcern.actor.create(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
          else #  monograph.press != 'gabii' # don't edit Gabii monographs with this script
            if check_for_changes_isbn(monograph, attrs, row_num)
              # backup_file = open_backup_file(input_file) if !backup_file_created
              # backup_file_created = true
              #
              # CSV.open(backup_file, "a") do |csv|
              #   exporter = Export::Exporter.new(monograph.id, :monograph)
              #   csv << exporter.monograph_row
              # end
              # Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
            end
          end

        end
      end
    end

    # puts "\nChanges were made. All uniquely identified Monographs with pending changes first had their metadata backed up to #{backup_file}" if backup_file_created
  end
end
