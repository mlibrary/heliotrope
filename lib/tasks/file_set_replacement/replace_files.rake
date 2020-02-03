desc 'replace the original_file for any FileSet whose label uniquely matches a file in the directory'
namespace :heliotrope do
  task :replace_files, [:directory, :monograph_id] => :environment do |_t, args|
    # A task to replace files in Fulcrum by exact filename match, optionally restricted to a specific Monograph
    # Usage (Monograph NOID optional): bundle exec rake "heliotrope:replace_files[/path/to/replacement/files/dir, 999999999]"
    args.with_defaults(monograph_id: nil)

    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    new_file_paths = Dir.glob(File.join(args.directory, '*'))

    replaced_count = 0

    new_file_paths.each do |new_file_path|
      new_file = File.basename(new_file_path)
      matches = args.monograph_id.present? ? FileSet.where(monograph_id_ssim: args.monograph_id, label: new_file) : FileSet.where(label: new_file)
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
        f = FileSet.where(label: new_file).first

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
