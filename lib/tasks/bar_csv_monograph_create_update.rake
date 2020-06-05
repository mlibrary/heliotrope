# frozen_string_literal: true

# note: This is basically the lib/tasks/tmm/tmm_csv_monograph_create_update.rake script with the backup-Monographs-metadata-first stuff commented out

require 'htmlentities'
require 'csv'

desc 'Task to be called by a cron for Monographs create/edit from TMM CSV files (ISBN lookup)'
namespace :heliotrope do
  task :bar_csv_monograph_create_update, [:bar_csv_file] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:bar_csv_monograph_create_update[/path/to/bar_csv_file]"

    fail "CSV file not found: '#{args.bar_csv_file}'" unless File.exist?(args.bar_csv_file)

    puts "Parsing file: #{args.bar_csv_file}"
    rows = CSV.read(args.bar_csv_file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

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

          # BAR Number goes in `identifier` with a prefix
          bar_number = row['Identifier(s)']
          identifier = []
          identifier << 'bar_number: ' + bar_number unless bar_number.blank?
          identifier.present? ? attrs['identifier'] = identifier : attrs.delete('identifier')

          # we store title and subtitle in a single string
          if attrs['title'].present? && row['Sub-Title'].present?
            title = attrs['title'].first.strip + ': ' + row['Sub-Title'].strip
            attrs['title'] = Array(title)
          end

          attrs['date_created'] = Array(Date.strptime(attrs['date_created'].first, '%m/%d/%y').strftime('%Y-%m-%d')) if attrs['date_created'].present?

          # we're not using incoming language values for BAR yet, as they are not suitable for facets
          attrs.delete('language')

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

            # NB: This Monograph creation line is commented out to allow a manual check first
            # Hyrax::CurationConcern.actor.create(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
          else #  monograph.press != 'gabii' # don't edit Gabii monographs with this script
            if check_for_changes_isbn(monograph, attrs, row_num)
              # NB: This Monograph editing line is commented out to allow a manual check first
              # Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
            end
          end

        end
      end
    end
  end
end
