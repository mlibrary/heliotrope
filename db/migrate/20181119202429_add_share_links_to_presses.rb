class AddShareLinksToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :share_links, :boolean, :default => false
  end
end
