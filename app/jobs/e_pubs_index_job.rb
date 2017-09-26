# frozen_string_literal: true

class EPubsIndexJob < ApplicationJob
  queue_as :epub_index

  def perform(epub_id)
    epub_publication = EPub::Publication.from(epub_id)
    sql_lite = EPub::SqlLite.from(epub_publication)
    sql_lite.create_table
    sql_lite.load_chapters
  end
end
