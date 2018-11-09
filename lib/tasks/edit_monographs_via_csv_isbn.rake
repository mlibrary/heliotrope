# frozen_string_literal: true

desc 'Lookup Monographs via e-book ISBN and update them from a CSV file'
namespace :heliotrope do
  task :edit_monographs_via_csv_isbn, [:input_file, :user_key] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_monographs_via_csv_isbn[/path/to/monographs.csv, <user's email>]"

    fail "CSV file not found '#{args.input_file}'" unless File.exist?(args.input_file)
    fail "User not found '#{args.user_key}'" unless User.where(user_key: args.user_key).count == 1

    puts "Parsing file: #{args.input_file}"
    rows = CSV.read(args.input_file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    monograph_fields = METADATA_FIELDS.select { |f| %i[universal monograph].include? f[:object] }

    check_for_unexpected_columns_isbn(rows, monograph_fields)

    # human-readable row counter (accounts for the top two discarded rows)
    row_num = 2
    rows.delete(0) # ditch the instruction placeholder row

    backed_up = false
    backup_file = ''

    # used to enable deletion of existing values
    blank_metadata = monograph_fields.pluck(:metadata_name).map{ |name| [name, nil] }.to_h

    rows.each do |row|
      row_num += 1

      # We're going to find Monographs by e-book ISBN. Get it separately so we can check it.
      # Note: in future we might allow any ISBN to be used?
      ebook_isbn = ''

      # ISBN(s) is a multi-valued field with entries separated by a ';'
      row['ISBN(s)']&.split(';')&.map(&:strip)&.each do |isbn|
        isbn = isbn.gsub('-', '').downcase
        ebook_isbn = isbn.sub(/\s*\(.+\)$/, '').delete('^0-9').strip if isbn[/\(([^()]*)\)/]&.gsub(/\(|\)/, '')&.strip == 'ebook'
      end
      # right now we expect all Michigan EPUBS (e.g. EBC) to be entered with an (e-book) ISBN
      if ebook_isbn.blank?
        puts "ISBN (e-book) missing on row #{row_num} ...................... SKIPPING ROW"
        next
      else
        matches = Monograph.where(isbn_ssim: ebook_isbn)

        if matches.count.zero?
          puts "No Monograph found with e-book ISBN #{ebook_isbn} on row #{row_num} ............ SKIPPING ROW"
          next
        elsif matches.count > 1 # should be impossible
          puts "More than 1 Monograph found with e-book ISBN #{ebook_isbn} on row #{row_num} ... SKIPPING ROW"
          next
        else
          monograph = matches.first
          current_ability = Ability.new(User.where(user_key: args.user_key).first)
          puts "User doesn't have edit privileges for Monograph with e-book ISBN #{ebook_isbn} on row #{row_num} ... SKIPPING ROW" unless current_ability.can?(:edit, monograph)

          attrs = {}
          Import::RowData.new.data_for_monograph(row, attrs)

          # blank Monograph titles caused problems. We don't allow them in the importer and shouldn't here either.
          if attrs['title'].blank?
            puts "Monograph title is blank on row #{row_num} ............ SKIPPING ROW"
            next
          end

          # in order to offer the ability to blank out metadata we need to merge in some nils
          attrs = blank_metadata.merge(attrs)

          # TODO: decide if it's worth offering the user a chance to bow-out based on the messages, as is done in the importer
          if check_for_changes_isbn(monograph, attrs, ebook_isbn) && !backed_up
            backup_file = paranoid_backup_isbn(rows, args.input_file)
            backed_up = true
          end

          # TODO: Maybe use a simplified UpdateMonographJob, when things settle. Metadata-only's not too slow tho.
          Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
        end
      end
    end

    puts "\nChanges were made. All Monographs with an (e-book) ISBN first had their metadata backed up to #{backup_file}" if backed_up
  end

  def check_for_unexpected_columns_isbn(rows, monograph_fields)
    # look for unexpected column names which will be ignored.
    # note: 'NOID', 'Link' are not in METADATA_FIELDS, they're export-only fields.
    unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - monograph_fields.pluck(:field_name) - ['NOID', 'Link']
    puts "***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped: #{unexpecteds.join(', ')}\n\n" if unexpecteds.present?
  end

  def check_for_changes_isbn(monograph, attrs, ebook_isbn)
    column_names = METADATA_FIELDS.pluck(:metadata_name).zip(METADATA_FIELDS.pluck(:field_name)).to_h
    changes = false
    changes_message = "Checking Monograph with e-book ISBN #{ebook_isbn} and noid #{monograph.id}"

    attrs.each do |key, value|
      if value.present?
        if monograph.public_send(key) != value
          changes = true
          changes_message += "\n        #{column_names[key]} will change to: #{value}"
        end
      end
    end

    changes_message += " ...................... NO CHANGES" if !changes
    puts changes_message
    return changes
  end

  def paranoid_backup_isbn(rows, path)
    # although any ISBN should do for lookup, we're assuming only the e-book ISBN is likely to be in Fulcrum
    isbns = ebook_isbns(rows)
    writable = File.writable?(File.dirname(path))
    backup_file = if writable
                    path.sub('.csv', '') + Time.now.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  else
                    '/tmp/' + File.basename(path).sub('.csv', '') + Time.now.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  end
    Rake::Task['heliotrope:edit_monographs_output_csv_isbn'].invoke(backup_file, *isbns)
    return backup_file
  end

  def ebook_isbns(rows)
    ebook_isbns = []
    all_isbns = rows.pluck('ISBN(s)')
    all_isbns.each do |isbn_field|
      isbn_values = isbn_field&.split(';')&.map(&:strip)

      isbn_values&.each do |isbn_value|
        isbn_value = isbn_value.gsub('-', '').downcase
        ebook_isbns << isbn_value.sub(/\s*\(.+\)$/, '').delete('^0-9').strip if isbn_value[/\(([^()]*)\)/]&.gsub(/\(|\)/, '')&.strip == 'ebook'
      end
    end
    ebook_isbns
  end
end
