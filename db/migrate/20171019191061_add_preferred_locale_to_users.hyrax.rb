# This migration comes from hyrax (originally 20170905135339)
class AddPreferredLocaleToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :preferred_locale, :string
  end
end
