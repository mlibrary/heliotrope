# frozen_string_literal: true

desc 'replace the original_file for any FileSet whose label uniquely matches a file in the directory'
namespace :heliotrope do
  task :replace_files, [:directory] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:replace_files[/path/to/replacement/files/dir]"
    fail "Directory not found: #{args.directory}" unless File.exist?(args.directory)
    new_file_paths = Dir.glob(File.join(args.directory, '*'))

    replaced_count = 0

    new_file_paths.each do |new_file_path|
      new_file = File.basename(new_file_path)
      matches = FileSet.where(label: new_file)

      if matches.count.zero?
        puts 'No FileSet found with label "' + new_file + '"............... SKIPPING'
      elsif matches.count > 1
        puts 'More than 1 FileSet found with label "' + new_file + '"...... SKIPPING'
      else
        replaced_count += 1
        puts '1 FileSet found with label "' + new_file + '"............... REPLACING'
        f = matches.first
        f.files.each(&:delete)

        # f now contains references to tombstoned files, so pull the FileSet object again to avoid any...
        # Ldp::Gone errors in Hydra::Works::AddFileToFileSet
        f = FileSet.where(label: new_file).first

        Hydra::Works::AddFileToFileSet.call(f, File.open(new_file_path), :original_file)
        # note: CharacterizeJob will queue up UnpackJob if the file being replaced is a FeaturedRepresentative
        CharacterizeJob.perform_later(f, f.original_file.id, nil)
      end
    end

    puts "\nDONE. " + replaced_count.to_s + ' files were replaced.'
  end
end
