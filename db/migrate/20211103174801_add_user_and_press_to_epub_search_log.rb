class AddUserAndPressToEpubSearchLog < ActiveRecord::Migration[5.2]
  def change
    add_column :epub_search_logs, :user, :string
    add_column :epub_search_logs, :press, :string
  end
end
