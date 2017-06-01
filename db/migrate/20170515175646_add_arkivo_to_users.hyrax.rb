# This migration comes from hyrax (originally 20160516190435)
class AddArkivoToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :arkivo_token, :string
    add_column :users, :arkivo_subscription, :string
    add_column :users, :zotero_token, :binary
    add_column :users, :zotero_userid, :string
  end
end
