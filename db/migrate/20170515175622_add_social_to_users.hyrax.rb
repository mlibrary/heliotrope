# This migration comes from hyrax (originally 20160328222156)
class AddSocialToUsers < ActiveRecord::Migration[4.2]
  def self.up
    add_column :users, :facebook_handle, :string
    add_column :users, :twitter_handle, :string
    add_column :users, :googleplus_handle, :string
  end

  def self.down
    remove_column :users, :facebook_handle, :string
    remove_column :users, :twitter_handle, :string
    remove_column :users, :googleplus_handle, :string
  end
end
