# frozen_string_literal: true

desc 'Update any number of objects using provided CSV file'
namespace :heliotrope do
  task :edit_objects_via_csv_noid, [:input_file, :user_key] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_objects_via_csv_noid[/path/to/edited_object_metadata.csv, <optionally user's email>]"

    args.with_defaults(user_key: ::User.batch_user_key)

    fail "CSV file not found '#{args.input_file}'" unless File.exist?(args.input_file)
    fail "User not found '#{args.user_key}'" unless User.where(user_key: args.user_key).count == 1

    puts "Parsing file: #{args.input_file}"
    rows = CSV.read(args.input_file, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    # as the attr will be going straight to an update actor, we need to remove non-Fedora fields
    non_fedora_fields = ((::ADMIN_METADATA_FIELDS + ::FILE_SET_FLAG_FIELDS).pluck :metadata_name).push(::MONO_FILENAME_FLAG)

    check_for_unexpected_columns(rows)

    # human-readable row counter (accounts for the header row)
    row_num = 1
    # rows.delete(0) # we normally ditch the instruction placeholder row, but there shouldn't be one here

    # used to check for valid NOIDs
    noid_chars = ('a'..'z').to_a + ('A'..'Z').to_a + ('0'..'9').to_a

    rows.each do |row|
      row_num += 1

      # Import::RowData is not aware of any NOID column. Get it separately and check it.
      noid = row['NOID']
      if noid.blank?
        puts "NOID missing on row #{row_num} ...................... SKIPPING ROW"
        next
      elsif noid.length != 9 || !noid.chars.all? { |ch| noid_chars.include?(ch) }
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

          current_ability = Ability.new(User.where(user_key: args.user_key).first)
          puts "User doesn't have edit privileges for #{object.class.to_s} with NOID #{noid} on row #{row_num} ... SKIPPING ROW" unless current_ability.can?(:edit, object)

          attrs = {}
          Import::RowData.new.field_values(object.class.to_s.underscore.to_sym, row, attrs)
          attrs = attrs.except(non_fedora_fields)

          if check_for_changes(object, attrs)
            if object.class == Monograph
              Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(object, current_ability, attrs))
            else
              Hyrax::CurationConcern.file_set_update_actor.update(Hyrax::Actors::Environment.new(object, current_ability, attrs))
            end
          end
        end
      end
    end
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
    changes_message = "Checking #{object.class.to_s} with noid #{object.id}"

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
    return changes
  end
end
