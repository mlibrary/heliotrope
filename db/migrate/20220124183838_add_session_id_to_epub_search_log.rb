class AddSessionIdToEpubSearchLog < ActiveRecord::Migration[5.2]
  def change
    add_column :epub_search_logs, :session_id, :string
  end
end
