# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

desc 'Removes derivatives of deleted FileSets'
namespace :heliotrope do
  task remove_derivatives_of_deleted_file_sets: :environment do
    # Usage: bundle exec rails heliotrope:remove_derivatives_of_deleted_file_sets

    empty_folders_deleted_count = 0
    level_4_folders_deleted = 0
    # `du` options used: summarize, megabytes, dereference symbolic links (production uses a symlinked dir)
    derivatives_start_total_in_mb = `du -smL "#{Hyrax.config.derivatives_path}"`.split(/\t/, 2).first

    level_1_dirs_to_delete = []

    Dir.glob("#{File.join(Hyrax.config.derivatives_path, '/[a-z0-9][a-z0-9]/')}") do |level_1_dir|
      level_2_dirs_to_delete = []
      level_2_dirs = Dir.glob("#{File.join(level_1_dir, '/[a-z0-9][a-z0-9]/')}")

      level_2_dirs.each do |level_2_dir|
        level_3_dirs_to_delete = []
        level_3_dirs = Dir.glob("#{File.join(level_2_dir, '/[a-z0-9][a-z0-9]/')}")

        level_3_dirs.each do |level_3_dir|
          level_4_dirs_to_delete = []
          level_4_dirs = Dir.glob("#{File.join(level_3_dir, '/[a-z0-9][a-z0-9]/')}")

          level_4_dirs.each do |level_4_dir|
            # see if any file or directory exists in here that would give us the NOID's final (check) character
            derivative_file_or_directory = Dir.glob("#{File.join(level_4_dir, '/[a-z0-9]-*')}").first

            if derivative_file_or_directory.blank?
              puts "Deleting empty derivative folder: #{level_4_dir}"
              level_4_dirs_to_delete << level_4_dir
              next
            end

            # the capture parens are kind of hard to spot here but they are surrounding the 9 characters of the NOID
            noid = derivative_file_or_directory.match("#{File.join(Hyrax.config.derivatives_path, '([a-z0-9][a-z0-9]', '[a-z0-9][a-z0-9]', '[a-z0-9][a-z0-9]', '[a-z0-9][a-z0-9]', '[a-z0-9]-)')}")&.captures&.first&.gsub(/[^a-z0-9]/, '')
            # this really doesn't seem possible based on the regex capture above
            if noid&.length != 9
              puts "NOID length is not 9! ... #{noid}"
              next
            end

            ActiveFedora::Base.find(noid)

          rescue Hyrax::ObjectNotFoundError, ActiveFedora::ObjectNotFoundError, Ldp::Gone
            puts "Deleting derivative folder of missing FileSet #{noid}: #{level_4_dir}"
            level_4_dirs_to_delete << level_4_dir
          rescue StandardError => e
            puts "Accessing NOID #{noid} caused StandardError #{e.message}"
          end

          level_4_folders_deleted += level_4_dirs_to_delete.count
          level_4_dirs_to_delete.each { |level_4_dir_to_delete| FileUtils.rm_rf(level_4_dir_to_delete) }
          level_4_dirs = Dir.glob("#{File.join(level_3_dir, '/[a-z0-9][a-z0-9]/')}")

          if level_4_dirs.blank?
            puts "Deleting empty level 3 folder: #{level_3_dir}"
            level_3_dirs_to_delete << level_3_dir
            next
          end
        end
        empty_folders_deleted_count += level_3_dirs_to_delete.count
        level_3_dirs_to_delete.each { |level_3_dir_to_delete| FileUtils.rm_rf(level_3_dir_to_delete) }
        level_3_dirs = Dir.glob("#{File.join(level_2_dir, '/[a-z0-9][a-z0-9]/')}")

        if level_3_dirs.blank?
          puts "Deleting empty level 2 folder: #{level_2_dir}"
          level_2_dirs_to_delete << level_2_dir
          next
        end
      end
      empty_folders_deleted_count += level_2_dirs_to_delete.count
      level_2_dirs_to_delete.each { |level_2_dir_to_delete| FileUtils.rm_rf(level_2_dir_to_delete) }
      level_2_dirs = Dir.glob("#{File.join(level_1_dir, '/[a-z0-9][a-z0-9]/')}")

      if level_2_dirs.blank?
        puts "Deleting empty level 1 folder: #{level_1_dir}"
        level_1_dirs_to_delete << level_1_dir
        next
      end
    end
    empty_folders_deleted_count += level_1_dirs_to_delete.count
    level_1_dirs_to_delete.each { |level_1_dir_to_delete| FileUtils.rm_rf(level_1_dir_to_delete) }

    if level_4_folders_deleted > 0 || empty_folders_deleted_count > 0
      # `du` options used: summarize, megabytes, dereference symbolic links (production uses a symlinked dir)
      derivatives_end_total_in_mb = `du -smL "#{Hyrax.config.derivatives_path}"`.split(/\t/, 2).first

      puts "#{level_4_folders_deleted} bottom-level, derivative-containing folders deleted."
      puts "#{empty_folders_deleted_count} empty parent folders deleted."
      puts "Initial derivatives folder size was #{derivatives_start_total_in_mb}MB."
      puts "Final derivatives folder size was #{derivatives_end_total_in_mb}MB."
    else
      puts "No deletions made."
      puts "Derivatives folder size is #{derivatives_start_total_in_mb}MB"
    end
  end
end
