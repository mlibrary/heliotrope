# This migration comes from hyrax (originally 20160328222230)
class AddOrcidToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :orcid, :string
  end
end
