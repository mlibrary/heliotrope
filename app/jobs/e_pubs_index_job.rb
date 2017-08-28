# frozen_string_literal: true

class EPubsIndexJob < ApplicationJob
  queue_as :epub_index

  # This `perform_later` should be the last thing called by
  # EPubServiceJob as it relies on the cached EPub existing
  def perform(epub_id)
    epub_path = ::EPubsService.epub_path(epub_id)
    db_file = "#{epub_path}/#{epub_id}.db"

    lite = EPubsIndexService::SqlLite.new(db_file)
    lite.create_table

    epub = EPubsIndexService::EPub.new(epub_path)

    chapters = EPubsIndexService::Chapters.create(epub)

    lite.load_chapters(chapters)
  end
end
