# frozen_string_literal: true

class RenameIntervalAndAddEpubChapterDownloadsToPresses < ActiveRecord::Migration[6.1]
  def change
    change_table :presses, bulk: true do |t|
      t.rename :interval, :pdf_chapter_downloads
      t.boolean :epub_chapter_downloads, default: false, after: :aboutware
    end
  end
end
