# frozen_string_literal: true

desc 'Update any number of objects using provided CSV file'
namespace :heliotrope do
  task :edit_objects_via_csv, [:input_file] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_objects_via_csv[/path/to/edited_object_metadata.csv]"

    fail "CSV file not found '#{args.input_file}'" unless File.exist?(args.input_file)

    puts "NB: this script only edits metadata in Fedora, it cannot set FeaturedRepresentatives or publish objects"

    puts "Parsing file: #{args.input_file}"
    rows = CSV.read(args.input_file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    # as the attr will be going straight to an update actor, we need to remove non-Fedora fields
    non_fedora_fields = ((::ADMIN_METADATA_FIELDS + ::FILE_SET_FLAG_FIELDS).pluck :metadata_name).push(::MONO_FILENAME_FLAG)

    check_for_unexpected_columns(rows)

    # human-readable row counter (accounts for the header row)
    row_num = 1
    # rows.delete(0) # we normally ditch the instruction placeholder row, but there shouldn't be one here

    backup_file = ''
    backup_file_created = false

    rows.each do |row|
      row_num += 1

      # Import::RowData is not aware of any NOID column. Get it separately and check it.
      noid = row['NOID']
      if noid.blank?
        clean_isbns = []
        # ISBN(s) is a multi-valued field with entries separated by a ';'
        row['ISBN(s)']&.split(';')&.map(&:strip)&.each do |isbn|
          isbn = isbn.delete('-').downcase
          clean_isbns << isbn.sub(/\s*\(.+\)$/, '').delete('^0-9').strip
        end

        # sometimes ISBNs come in as just a format, with no actual number, like `(Paper)`, so at this point they're blank
        clean_isbns = clean_isbns.reject(&:blank?)

        if clean_isbns.blank?
          puts "No NOID or ISBN(s) found on row #{row_num} ...................... SKIPPING ROW"
          next
        else
          matches = Monograph.where(isbn_numeric: clean_isbns)

          if matches.count.zero?
            puts "No Monograph found using ISBN(s) '#{clean_isbns.join('; ')}' on row #{row_num} .......... SKIPPING ROW"
            next
          elsif matches.count > 1 # shouldn't happen
            puts "More than 1 Monograph found using ISBN(s) #{clean_isbns.join('; ')} on row #{row_num} (see below) ... SKIPPING ROW"
            matches.each { |m| puts Rails.application.routes.url_helpers.hyrax_monograph_url(m.id) }
            puts
            next
          else
            noid = matches.first.id
          end
        end
      end

      if !/^[[:alnum:]]{9}$/.match?(noid)
        puts "Invalid NOID #{noid} on row #{row_num} .............. SKIPPING ROW"
        next
      else
        matches = ActiveFedora::Base.where(id: noid)
        if matches.count.zero?
          puts "No Object found with NOID #{noid} on row #{row_num} ............ SKIPPING ROW"
          next
        elsif matches.count > 1 # should be impossible
          puts "More than 1 Object found with NOID #{noid} on row #{row_num} ... SKIPPING ROW"
          next
        else
          object = matches.first
          if [FileSet, Monograph].exclude? object.class
            puts "Object must be a Monograph or a FileSet"
            next
          end

          current_ability = Ability.new(User.where(user_key: ::User.batch_user_key).first)

          attrs = {}
          Import::RowData.new.field_values(object.class.to_s.underscore.to_sym, row, attrs)
          attrs = attrs.except(non_fedora_fields)

          if check_for_changes(object, attrs)
            backup_file = open_backup_file(args.input_file) if !backup_file_created
            backup_file_created = true

            if object.class == Monograph
              presenter = Hyrax::PresenterFactory.build_for(ids: [object.id], presenter_class: Hyrax::MonographPresenter, presenter_args: nil).first

              CSV.open(backup_file, "a") do |csv|
                exporter = Export::Exporter.new(nil)
                csv << exporter.metadata_row(presenter)
              end

              Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(object, current_ability, attrs))
            else
              presenter = Hyrax::PresenterFactory.build_for(ids: [object.id], presenter_class: Hyrax::FileSetPresenter, presenter_args: nil).first

              CSV.open(backup_file, "a") do |csv|
                exporter = Export::Exporter.new(nil)
                csv << exporter.metadata_row(presenter)
              end

              Hyrax::CurationConcern.file_set_update_actor.update(Hyrax::Actors::Environment.new(object, current_ability, attrs))
            end
          end
        end
      end
    end

    puts "\nChanges were made. Changed objects' metadata were first backed up to #{backup_file}" if backup_file_created
  end

  def check_for_unexpected_columns(rows)
    # look for unexpected column names which will be ignored.
    # don't warn user for any fields that may have been output by the exporter, as they may be using its output as a starting point
    unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - METADATA_FIELDS.pluck(:field_name) - ADMIN_METADATA_FIELDS.pluck(:field_name) - FILE_SET_FLAG_FIELDS.pluck(:field_name)
    puts "***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped: #{unexpecteds.join(', ')}\n\n" if unexpecteds.present?
  end

  def check_for_changes(object, attrs)
    column_names = METADATA_FIELDS.pluck(:metadata_name).zip(METADATA_FIELDS.pluck(:field_name)).to_h
    changes = false
    changes_message = "Checking #{object.class} with noid #{object.id}"

    attrs.each do |key, value|
      multivalued = METADATA_FIELDS.select { |x| x[:metadata_name] == key }.first[:multivalued]
      current_value = field_value(object, key, multivalued)

      # to make the "orderless" array comparison meaningful, we sort the new values
      value = value&.sort if multivalued == :yes_split

      if value != current_value
        changes_message = "\n" + changes_message + "\nnote: only fields with pending changes are shown\n" if !changes
        changes = true
        changes_message += "\n*** #{column_names[key]} ***\nCURRENT VALUE: #{current_value}\n    NEW VALUE: #{value}"
      end
    end
    changes_message = changes ? changes_message + "\n\n" : changes_message + '...................... NO CHANGES'
    puts changes_message if changes
    changes
  end

  def open_backup_file(path)
    writable = File.writable?(File.dirname(path))
    backup_file = if writable
                    path.sub('.csv', '') + '_' + Time.now.getlocal.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  else
                    '/tmp/' + File.basename(path).sub('.csv', '') + '_' + Time.now.getlocal.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  end

    CSV.open(backup_file, "w") do |csv|
      exporter = Export::Exporter.new(nil, :all)
      exporter.write_csv_header_rows(csv)
    end

    backup_file
  end
end
