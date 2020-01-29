# frozen_string_literal: true

require 'htmlentities'

# TODO: merge fixes into edit_monograph_via_csv_noid.rake and/or pull common functionality into one or more Service(s)
# TODO: offer publisher and visibility as options, maybe

# note: I've left the call to Hyrax::CurationConcern.actor.update commented out as a rudimentary way to see what...
#         changes will be made before triggering the updates

desc 'Lookup Monographs via ISBNs and update them from a CSV file'
namespace :heliotrope do
  task :edit_monographs_via_csv_isbn, [:input_file, :user_key] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:edit_monographs_via_csv_isbn[/path/to/monographs.csv, <user's email>]"

    fail "CSV file not found '#{args.input_file}'" unless File.exist?(args.input_file)
    fail "User not found '#{args.user_key}'" unless User.where(user_key: args.user_key).count == 1

    puts "Parsing file: #{args.input_file}"
    rows = CSV.read(args.input_file, encoding: 'windows-1252:utf-8', headers: true, skip_blanks: true).delete_if { |row| row.to_hash.values.all?(&:blank?) }

    monograph_fields = METADATA_FIELDS.select { |f| %i[universal monograph].include? f[:object] }

    check_for_unexpected_columns_isbn(rows, monograph_fields)

    row_num = 1

    backup_file = ''
    backup_file_created = false

    # used to enable deletion of existing values
    blank_metadata = monograph_fields.pluck(:metadata_name).map{ |name| [name, nil] }.to_h

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
        matches = Monograph.where(isbn_numeric: clean_isbns)

        if matches.count.zero?
          puts "No Monograph found using ISBN(s) '#{clean_isbns.join('; ')}' on row #{row_num} .......... SKIPPING ROW"
          next
        elsif matches.count > 1 # shouldn't happen
          puts "More than 1 Monograph found using ISBN(s) #{clean_isbns.join('; ')} on row #{row_num} ... SKIPPING ROW"
          matches.each { |m| puts Rails.application.routes.url_helpers.hyrax_monograph_url(m.id) }
          puts
          next
        else
          monograph = matches.first

          current_ability = Ability.new(User.where(user_key: args.user_key).first)
          puts "User doesn't have edit privileges for Monograph with NOID #{monograph.id} on row #{row_num} ... SKIPPING ROW" unless current_ability.can?(:edit, monograph)

          attrs = {}
          Import::RowData.new.field_values(:monograph, row, attrs)

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
          attrs = cleanup_characters(attrs)

          # TODO: decide if it's worth offering the user a chance to bow-out based on the messages, as is done in the importer
          if check_for_changes_isbn(monograph, attrs, row_num)
            backup_file = open_backup_file(args.input_file) if !backup_file_created
            backup_file_created = true

            CSV.open(backup_file, "a") do |csv|
              exporter = Export::Exporter.new(monograph.id, :monograph)
              csv << exporter.monograph_row
            end
          end

          # TODO: Maybe use a simplified UpdateMonographJob, when things settle. Metadata-only's not too slow tho.
          #### Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(monograph, current_ability, attrs))
          # puts attrs
        end
      end
    end

    puts "\nChanges were made. All uniquely identified Monographs with pending changes first had their metadata backed up to #{backup_file}" if backup_file_created
  end

  def check_for_unexpected_columns_isbn(rows, monograph_fields)
    # look for unexpected column names which will be ignored.
    # note: 'NOID', 'Link' are not in METADATA_FIELDS, they're export-only fields.
    unexpecteds = rows[0].to_h.keys.map { |k| k&.strip } - monograph_fields.pluck(:field_name) - ['NOID', 'Link']
    puts "***TITLE ROW HAS UNEXPECTED VALUES!*** These columns will be skipped: #{unexpecteds.join(', ')}\n\n" if unexpecteds.present?
  end

  def maybe_convert_to_markdown(attrs)
    attrs_out = {}
    attrs.each do |key, value|
      if value.present?
        # it looks like `description` is the only field with HTML in it, so no point doing the clever thing for now
        attrs_out[key] = if key.downcase == 'description' # if ActionController::Base.helpers.strip_tags(value) != value
                           # 1) HTMLEntities is cleaning up the many HTML entity and decimal codes in the TMM HTML data
                           # 2) the calls to gsub are getting rid of an inordiante number of non-breaking spaces,...
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
  def cleanup_characters(attrs)
    attrs_out = {}
    attrs.each do |key, value|
      # At this point the cardinality is as required by ActiveFedora, ready to be set. Store it for later.
      is_array = value.kind_of?(Array)
      # Array wrap for uniform processing.
      cleaned_value = clean_values(Array(value))
      # back to expected AF cardinality
      attrs_out[key] = is_array ? cleaned_value : cleaned_value.first
    end
    attrs_out
  end

  def clean_values(values)
    cleaned_values = []

    values.each do |value|
       if value.present?
        # value = value.gsub('–', '-') # endash
        # value = value.gsub('—', '--') # emdash
        value = value.gsub(/[‘’]/, "'") # left, right single quotation marks
        value = value.gsub(/[“”]/, '"') # left, right double quotation marks
        cleaned_values << value.gsub('…', '...') # horizontal ellipsis
      else
        cleaned_values << nil
      end
    end

    cleaned_values
  end


  def check_for_changes_isbn(monograph, attrs, row_num)
    column_names = METADATA_FIELDS.pluck(:metadata_name).zip(METADATA_FIELDS.pluck(:field_name)).to_h
    changes = false
    changes_message = "Checking Monograph with ISBNs #{monograph.isbn.join('; ')} and NOID #{monograph.id} on row #{row_num}"

    attrs.each do |key, value|
        multivalued = METADATA_FIELDS.select { |x| x[:metadata_name] == key }.first[:multivalued]
        current_value = field_value(monograph, key, multivalued)

        # to make the "orderless" array comparison meaningful, we sort the new values just as we do in the...
        # stolen-from-Exporter field_value method below
        value = value&.sort if multivalued == :yes_split

        if value != current_value
          changes_message = "\n" + changes_message + "\nnote: only fields with pending changes are shown\n" if !changes
          changes = true
          changes_message += "\n*** #{column_names[key]} ***\nCURRENT VALUE: #{current_value}\n    NEW VALUE: #{value}"
        end
      end
    changes_message = changes ? changes_message + "\n\n" : changes_message + '...................... NO CHANGES'
    puts changes_message
    return changes
  end

  # stolen from Exporter, with the addition of Array-wrapping on the multivalued AF fields, to enable...
  # direct comparison with the ready-to-save AF data from RowData::field_values
  def field_value(item, metadata_name, multivalued)
    return if item.public_send(metadata_name).blank?
    if multivalued == :yes_split
      # Any intended order within a multi-valued field is lost after having been stored in an...
      # `ActiveTriples::Relation`, so I'm arbitrarily sorting them alphabetically.
      item.public_send(metadata_name).to_a.sort
    elsif multivalued == :yes
      # this is a multi-valued field but we're only using it to hold one value
      Array(item.public_send(metadata_name).first)
    elsif multivalued == :yes_multiline
      item.public_send(metadata_name).to_a
    else
      item.public_send(metadata_name)
    end
  end

  def open_backup_file(path)
    writable = File.writable?(File.dirname(path))
    backup_file = if writable
                    path.sub('.csv', '') + '_' + Time.now.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  else
                    '/tmp/' + File.basename(path).sub('.csv', '') + '_' + Time.now.strftime("%Y%m%dT%H%M%S") + '.bak.csv'
                  end

    CSV.open(backup_file, "w") do |csv|
      exporter = Export::Exporter.new(nil, :monograph)
      exporter.write_csv_header_rows(csv)
    end

    return backup_file
  end
end
