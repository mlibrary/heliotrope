# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

require 'htmlentities'

desc 'Task to be called by a cron for Monographs create/edit from TMM CSV files'
namespace :heliotrope do
  task :tmm_csv_monograph_create_update, [:tmm_csv_dir] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:tmm_csv_monograph_create_update[/path/to/tmm_csv_dir]"

    # note: fail messages will be emailed to MAILTO by cron *unless* you use 2>&1 at the end of the job line
    fail "CSV directory not found: '#{args.tmm_csv_dir}'" unless Dir.exist?(args.tmm_csv_dir)

    input_file = Dir.glob(File.join(args.tmm_csv_dir, "TMMEBCData_*#{Time.now.getlocal.strftime('%Y-%m-%d')}.csv")).sort.last
    fail "CSV file not found in directory '#{args.tmm_csv_dir}'" if input_file.blank?
    fail "CSV file may accidentally be a backup as '#{input_file}' contains 'bak'. Exiting." if input_file.include? 'bak'

    puts "Parsing file: #{input_file}"
    # we need UTF-8 and TMM needs to export UTF-16LE for now because of this kind of thing: https://dba.stackexchange.com/a/250018
    # unfortunately we need to read this file into memory to force uniform line endings before parsing the CSV.
    # side note: although the
    file_content = File.read(input_file, encoding: 'bom|utf-16le')
    # Use `gsub!` to avoid holding more memory (I guess).
    file_content.gsub!(/\r\n?/, "\n")

    rows = CSV.parse(file_content, headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }
    monograph_fields = METADATA_FIELDS.select { |f| %i[universal monograph].include? f[:object] }

    check_for_unexpected_columns_isbn(rows, monograph_fields)

    row_num = 1
    backup_file = ''
    backup_file_created = false

    # used to enable deletion of existing values
    blank_metadata = monograph_fields.pluck(:metadata_name).map { |name| [name, nil] }.to_h

    rows.each do |row|
      row_num += 1

      # For now this is the only place where we set a Monograph's press from a CSV column. Handle this field separately.
      # Every row should have a press set, but some use TMM names that need mapping to an actual Fulcrum subdomain.
      # We'll skip the row if no valid press is set.
      press = row['Press']&.strip

      if press.blank?
        puts "No Press value on row #{row_num} ... SKIPPING ROW"
        next
      end

      tmm_press_name_map = { 'umasp' => 'asp',
                             'umccs' => 'lrccs',
                             'umcjs' => 'cjs',
                             'umsa' => 'csas',
                             'umsea' => 'cseas' }


      press = tmm_press_name_map[press] if tmm_press_name_map[press].present?

      unless Press.exists?(subdomain: press)
        puts "Invalid Press value '#{press}' on row #{row_num} ... SKIPPING ROW"
        next
      end

      # ensure we're looking for the correct Press value in Fulcrum by editing the row before lookup
      row['Press'] = press
      matches, identifier = ObjectLookupService.matches_for_csv_row(row)

      if matches.count > 1 # shouldn't happen
        puts "More than 1 Monograph found using #{identifier} on row #{row_num} ... SKIPPING ROW"
        matches.each { |m| puts Rails.application.routes.url_helpers.hyrax_monograph_url(m.id) }
        puts
        next
      else
        new_monograph = matches.count.zero?
        monograph = new_monograph ? Monograph.new : matches.first

        current_ability = Ability.new(User.batch_user)

        attrs = {}
        Import::RowData.new.field_values(:monograph, row, attrs)
        attrs['press'] = press

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
          puts "No Monograph found using #{identifier} on row #{row_num} .......... CREATING in press '#{attrs['press']}'"
          attrs['visibility'] = 'restricted'

          Hyrax::CurationConcern.actor.create(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
        elsif monograph.press != 'gabii' # don't edit Gabii monographs with this script
          if check_for_changes_identifier(monograph, identifier, attrs, row_num)
            backup_file = open_backup_file(input_file) if !backup_file_created
            backup_file_created = true

            CSV.open(backup_file, "a") do |csv|
              exporter = Export::Exporter.new(monograph.id, :monograph)
              csv << exporter.monograph_row
            end
            Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
          end
        end
      end
    end

    puts "\nChanges were made. All uniquely identified Monographs with pending changes first had their metadata backed up to #{backup_file}" if backup_file_created
  end

  def check_for_unexpected_columns_isbn(rows, monograph_fields)
    # look for unexpected column names which will be ignored.
    # note: 'NOID', 'Link' are not in METADATA_FIELDS, they're export-only ADMIN_METADATA_FIELDS.
    # 'Press' is a new exception as it is a column sent from TMM but is not a "traditional" importer CSV field
    unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - monograph_fields.pluck(:field_name) - ['NOID', 'Link', 'Press']
    puts "***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped: #{unexpecteds.join(', ')}\n\n" if unexpecteds.present?
  end

  def maybe_convert_to_markdown(attrs)
    attrs_out = {}
    attrs.each do |key, value|
      if value.present?
        # TODO: maybe stop converting HTML to Markdown as HTML should work just fine in Fulcrum fields, theoretically
        #       otherwise a check like this might be better than listing fields:
        #       if ActionController::Base.helpers.strip_tags(value) != value
        attrs_out[key] = if ['title', 'description'].include? key.downcase
                           # 1) HTMLEntities is cleaning up the many HTML entity and decimal codes in the TMM HTML data
                           # 2) the calls to gsub are getting rid of an inordinate number of non-breaking spaces,...
                           # which appear in large numbers in the TMM data for seemingly no reason.
                           Array(HtmlToMarkdownService.convert(HTMLEntities.new.decode(value.first.gsub('&#160;', ' ').gsub('&nbsp;', ' '))))
                         else
                           value
                         end
      else
        attrs_out[key] = nil
      end
    end
    attrs_out
  end

  # this method expects HTMLEntities to have done its work in converting entities and decimal codes
  # TODO: this should happen somewhere else -- in RowData, or even in a before_save callback on both Monographs and FileSets?
  def cleanup_characters(attrs, new_monograph)
    attrs_out = {}
    attrs.each do |key, value|
      # At this point the cardinality is as required by ActiveFedora, ready to be set. Store it for later.
      is_array = value.kind_of?(Array)
      # Array wrap for uniform processing.
      cleaned_value = clean_values(Array(value), new_monograph)
      # back to expected AF cardinality
      attrs_out[key] = is_array ? cleaned_value : cleaned_value.first
    end
    attrs_out
  end

  def clean_values(values, new_monograph)
    cleaned_values = []

    values.each do |value|
      if value.present?
        value = value.gsub(/\r\n?/, "\n") # editors are on a mix of OS's so make line endings uniform
        # value = value.gsub('–', '-') # endash, commented out as apparently editors want to use them
        # value = value.gsub('—', '--') # emdash, commented out as apparently editors want to use them
        value = value.gsub(/[‘’]/, "'") # left, right single quotation marks
        value = value.gsub(/[“”]/, '"') # left, right double quotation marks

        # this line can be removed once this issue is closed. Note that the extra space...
        # should be removed on the next edit run as the issue does not affect Work updating
        # https://github.com/samvera/hyrax/issues/3527
        value = value + ' ' if new_monograph && value.end_with?('"') && value.include?("\n")

        cleaned_values << value.gsub('…', '...') # horizontal ellipsis
      else
        cleaned_values << nil
      end
    end

    # you can set all AF fields to nil, but not [nil], so don't send that back!
    cleaned_values == [nil] ? nil : cleaned_values
  end

  def check_for_changes_identifier(object, identifier, attrs, row_num)
    column_names = METADATA_FIELDS.pluck(:metadata_name).zip(METADATA_FIELDS.pluck(:field_name)).to_h
    changes = false
    changes_message = "Checking #{object.class} #{object.id}, found with #{identifier} on row #{row_num}"

    # check press separately, it's not in METADATA_FIELDS
    press_changing = false
    if object.class == Monograph && object.press != attrs['press']
      changes_message += "\n*** Press changing from #{object.press} to #{attrs['press']} ***"
      press_changing = true
    end

    attrs.each do |key, value|
      next if key == 'press'
      multivalued = METADATA_FIELDS.select { |x| x[:metadata_name] == key }.first[:multivalued]
      current_value = field_value(object, key, multivalued)

      # to make the "orderless" array comparison meaningful, we sort the new values just as we do in the...
      # stolen-from-Exporter field_value method below
      value = value&.sort if multivalued == :yes_split

      if value != current_value
        changes_message = "\n" + changes_message + "\nnote: only fields with pending changes are shown\n" if !changes
        changes = true
        changes_message += "\n*** #{column_names[key]} ***\nCURRENT VALUE: #{current_value}\n    NEW VALUE: #{value}"
      end
    end

    changes ||= press_changing
    changes_message = changes ? changes_message + "\n\n" : changes_message + '...................... NO CHANGES'
    puts changes_message if changes
    changes
  end

  def field_value(item, metadata_name, multivalued)
    return if item.public_send(metadata_name).blank?
    if multivalued == :yes_split
      # Any intended order within a multi-valued field is lost after having been stored in an...
      # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically.
      item.public_send(metadata_name).to_a.sort
    elsif [:yes, :yes_multiline].include? multivalued
      # `to_a` so we're not doing comparisons against `ActiveTriples::Relation`
      item.public_send(metadata_name).to_a
    else
      item.public_send(metadata_name)
    end
  end

  def open_backup_file(path)
    writable = File.writable?(File.dirname(path))
    backup_file = if writable
                    path.sub('.csv', '') + '_' + Time.now.getlocal.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  else
                    '/tmp/' + File.basename(path).sub('.csv', '') + '_' + Time.now.getlocal.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  end

    CSV.open(backup_file, "w") do |csv|
      exporter = Export::Exporter.new(nil, :monograph)
      exporter.write_csv_header_rows(csv)
    end

    backup_file
  end
end
