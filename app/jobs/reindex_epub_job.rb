# frozen_string_literal: true

class ReindexEpubJob < ApplicationJob
  def perform(id)
    db = File.join(UnpackService.root_path_from_noid(id, 'epub'), id + ".db")
    begin
      FileUtils.mv(db, db + ".old") if File.exist? db
      sqlite = EPub::SqlLite.from_directory(UnpackService.root_path_from_noid(id, 'epub'))
      sqlite.create_table
      sqlite.load_chapters
      FileUtils.rm db + ".old" if File.exist? db + ".old"
    rescue SQLite3::Exception => e
      Rails.logger.error("EPub Index #{db} not updated")
      Rails.logger.error(e.message)
    end
  end
end
