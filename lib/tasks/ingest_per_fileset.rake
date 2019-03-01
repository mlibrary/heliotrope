# frozen_string_literal: true

# This is really only to be used for a single 8500+ fileset monograph
# so is very specific. Could be generalized for other monographs with
# a very large number of assets

desc "Ingest a monograph + files one file at a time"
namespace :heliotrope do
  # To run: rake "heliotrope:ingest_per_fileset[/path/to/csv/file.csv, 999999999]"  # monograph id is optional
  task :ingest_per_fileset, [:csv_input_file, :optional_monograph_id] => :environment do |_t, args|
    attrs = Import::CSVParser.new(args.csv_input_file).attributes
    filenames = attrs.delete("files")
    file_metadata = attrs.delete("files_metadata")
    attrs.delete("row_errors")
    attrs['press'] = 'heb'
    attrs['visibility'] = 'restricted'
    user = User.batch_user
    current_ability = Ability.new(user)

    if args.optional_monograph_id.present?
      mono = Monograph.find args.optional_monograph_id
      puts "#{Time.new}: Using Monograph #{mono.id}"
    else
      mono = Monograph.new
      Hyrax::CurationConcern.actor.create(Hyrax::Actors::Environment.new(mono, current_ability, attrs))
      sleep(1) until (Resque.info[:pending] == 0 && Resque.info[:working] == 0)
      mono.reload
      puts "#{Time.new}: Monograph #{mono.id} created"
    end

    filenames.each_index do |i|
      sleep(1) until (Resque.info[:pending] == 0 && Resque.info[:working] == 0)

      file_set = FileSet.where(label: filenames[i])&.first
      if file_set.present? && file_set.original_file&.file_name&.first == filenames[i]
        # already ingested. just in case this rake task dies and we need to re-run it
        puts "#{Time.new}: #{filenames[i]} already ingested!"
      else
        file = File.join(File.dirname(args.csv_input_file), filenames[i])
        uploaded_file = Hyrax::UploadedFile.create(file: File.new(file), user: user)
        attrs['import_uploaded_files_ids'] = [uploaded_file['id']]
        attrs['import_uploaded_files_attributes'] = [file_metadata[i]]

        Hyrax::CurationConcern.actor.update(Hyrax::Actors::Environment.new(mono, current_ability, attrs))

        puts "#{Time.now}: Ingesting #{filenames[i]}"
      end
    end

    puts "#{Time.now}: Done"
  end
end
