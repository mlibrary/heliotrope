# frozen_string_literal: true

desc 'Update any number of Monographs using provided CSV file'
namespace :heliotrope do
  task :edit_monographs_via_csv, [:input_file, :user_key] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_monographs_via_csv[/path/to/monographs.csv, <user's email>]"

    fail "CSV file not found '#{args.input_file}'" unless File.exist?(args.input_file)
    fail "User not found '#{args.user_key}'" unless User.where(user_key: args.user_key).count == 1

    puts "Parsing file: #{args.input_file}"
    rows = CSV.read(args.input_file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    monograph_fields = METADATA_FIELDS.select { |f| %i[universal monograph].include? f[:object] }

    check_for_unexpected_columns(rows, monograph_fields)

    # human-readable row counter (3 accounts for the top two discarded rows)
    row_num = 3
    rows.delete(0) # ditch the instruction placeholder row

    backed_up = false
    backup_file = ''

    # used to check for valid NOIDs
    noid_chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a
    # used to enable deletion of existing values
    blank_metadata = monograph_fields.pluck(:metadata_name).map{ |name| [name, nil] }.to_h

    rows.each do |row|
      # Import::RowData is not aware of any NOID column. Get it separately and check it.
      noid = row['NOID']
      if noid.blank?
        puts "NOID missing on row #{row_num} ...................... SKIPPING ROW"
        next
      elsif noid.length != 9 || !noid.chars.all? { |ch| noid_chars.include?(ch) }
        puts "Invalid NOID #{noid} on row #{row_num} .............. SKIPPING ROW"
        next
      else
        matches = Monograph.where(id: noid)
        if matches.count.zero?
          puts "No Monograph found with NOID #{noid} on row #{row_num} ............ SKIPPING ROW"
          next
        elsif matches.count > 1 # should be impossible
          puts "More than 1 Monograph found with NOID #{noid} on row #{row_num} ... SKIPPING ROW"
          next
        else
          monograph = matches.first
          current_ability = Ability.new(User.where(user_key: args.user_key).first)
          puts "User doesn't have edit privileges for Monograph with NOID #{noid} on row #{row_num} ... SKIPPING ROW" unless current_ability.can?(:edit, monograph)

          attrs = {}
          Import::RowData.new.data_for_monograph(row, attrs)

          if attrs['title'].blank?
            puts "Monograph title is blank on row #{row_num} ............ SKIPPING ROW"
            next
          end
          # in order to offer the ability to blank out metadata we need to merge in some nils
          attrs = blank_metadata.merge(attrs)

          # TODO: decide if it's worth offering the user a chance to bow-out based on the messages, as is done in the importer
          if check_for_changes(monograph, attrs) && !backed_up
            backup_file = paranoid_backup(rows, args.input_file)
            backed_up = true
          end

          # TODO: Maybe use a simplified UpdateMonographJob, when things settle. Metadata-only's not too slow tho.
          Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
        end
      end
      row_num += 1
    end

    puts "\nChanges were made. All Monographs' metadata were first backed up to #{backup_file}" if backed_up
  end

  def check_for_unexpected_columns(rows, monograph_fields)
    # look for unexpected column names which will be ignored.
    # note: 'NOID', 'Link' are not in METADATA_FIELDS, they're export-only fields.
    unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - monograph_fields.pluck(:field_name) - ['NOID', 'Link']
    puts "***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped: #{unexpecteds.join(', ')}\n\n" if unexpecteds.present?
  end

  def check_for_changes(monograph, attrs)
    column_names = METADATA_FIELDS.pluck(:metadata_name).zip(METADATA_FIELDS.pluck(:field_name)).to_h
    changes = false
    changes_message = "Checking Monograph with noid #{monograph.id}"

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

  def paranoid_backup(rows, path)
    noids = rows.pluck('NOID')
    writable = File.writable?(File.dirname(path))
    backup_file = if writable
                    path.sub('.csv', '') + Time.now.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  else
                    '/tmp/' + File.basename(path).sub('.csv', '') + Time.now.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  end
    Rake::Task['heliotrope:edit_monographs_output_csv'].invoke(backup_file, *noids)
    return backup_file
  end
end
