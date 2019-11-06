# frozen_string_literal: true

class CleanupSmallEpubsJob < ApplicationJob
  def perform
    FileSet.all.each do |file_set|
      root_path = UnpackService.root_path_from_noid(file_set.id, 'epub')
      next unless Dir.exist?(root_path)

      sm_dir = File.join(root_path, file_set.id + '.sm')
      FileUtils.remove_entry_secure(sm_dir, true) if File.exist?(sm_dir)

      sm_epub = sm_dir + '.epub'
      FileUtils.remove_entry_secure(sm_epub, true) if File.exist?(sm_epub)
    end
  end
end
