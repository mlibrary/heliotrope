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

      matches, identifier = ObjectLookupService.matches_for_csv_row(row)

      if matches.count.zero?
        puts "No object found using #{identifier} on row #{row_num} ............ SKIPPING ROW"
        next
      elsif matches.count > 1 # should be impossible
        puts "More than 1 object found using #{identifier} on row #{row_num} ... SKIPPING ROW"
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

        if check_for_changes_identifier(object, identifier, attrs, row_num)
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
    puts "\nChanges were made. Changed objects' metadata were first backed up to #{backup_file}" if backup_file_created
  end

  def check_for_unexpected_columns(rows)
    # look for unexpected column names which will be ignored.
    # don't warn user for any fields that may have been output by the exporter, as they may be using its output as a starting point
    unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - METADATA_FIELDS.pluck(:field_name) - ADMIN_METADATA_FIELDS.pluck(:field_name) - FILE_SET_FLAG_FIELDS.pluck(:field_name)
    puts "***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped: #{unexpecteds.join(', ')}\n\n" if unexpecteds.present?
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
