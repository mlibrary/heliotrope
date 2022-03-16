# frozen_string_literal: true

desc 'replace the original_file for any FileSet whose label uniquely matches a file in the directory'
namespace :heliotrope do
  task :replace_files, [:directory, :monograph_id] => :environment do |_t, args|
    # A task to replace files in Fulcrum by exact filename match, optionally restricted to a specific Monograph
    # Usage (Monograph NOID optional): bundle exec rails "heliotrope:replace_files[/path/to/replacement/files/dir, <optional NOID or ISBN>]"
    args.with_defaults(monograph_id: nil)

    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    # we'll restrict this to files only, and they must be directly under the provided `args.directory`
    new_file_paths = Dir.glob(File.join(args.directory, '*')).select { |f| File.file?(f) }

    noid = nil

    if args.monograph_id.present?
      if /^[[:alnum:]]{9}$/.match?(args.monograph_id)
        noid = args.monograph_id
      else
        isbn = args.monograph_id.delete('^0-9') # we'll allow the ISBN to have spaces/hyphens and remove them here
        matches = Monograph.where(isbn_numeric: isbn)

        if matches.count.zero?
          raise "No Monograph found with ISBN #{isbn} ...................... EXITING"
        elsif matches.count > 1 # should be impossible
          raise "More than 1 Monograph found with ISBN #{isbn} ...................... EXITING"
        else
          noid = matches.first.id
          puts "ISBN #{isbn} matches Monograph with NOID #{noid}................... CONTINUING"
        end
      end
    end

    replaced_count = 0

    new_file_paths.each do |new_file_path|
      new_file = File.basename(new_file_path)
      matches = noid.present? ? FileSet.where(monograph_id_ssim: noid, label: new_file) : FileSet.where(label: new_file)
      monograph_message = args.monograph_id.present? ? "under Monograph #{args.monograph_id} " : ''

      if matches.count.zero?
        puts "No FileSet found with label #{new_file} #{monograph_message}............... SKIPPING"
      elsif matches.count > 1
        puts "More than 1 FileSet found with label #{new_file} #{monograph_message}...... SKIPPING"
      else
        replaced_count += 1
        puts "1 FileSet found with label #{new_file} #{monograph_message}............... REPLACING"
        f = matches.first
        f.files.each(&:delete)

        # f now contains references to tombstoned files, so pull the FileSet object again to avoid any...
        # Ldp::Gone errors in Hydra::Works::AddFileToFileSet
        # aside: I think f.reload would also work here
        f = FileSet.find(f.id)

        now = Hyrax::TimeService.time_in_utc
        f.date_uploaded = now
        f.date_modified = now
        # In the other FileSet replacement tasks we set the label and title here but as we can only find the file...
        # by its filename (`label` in the system) there should be no point overwriting `label` at all and `title`...
        # may in fact have already been customized to something other than the filename.
        f.save!

        Hydra::Works::AddFileToFileSet.call(f, File.open(new_file_path), :original_file)
        # note: CharacterizeJob will queue up UnpackJob if the file being replaced is a FeaturedRepresentative
        CharacterizeJob.perform_later(f, f.original_file.id, nil)
      end
    end

    puts "\nDONE. " + replaced_count.to_s + ' files were replaced.'
  end
end
