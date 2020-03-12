class AddDefaultListViewToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :default_list_view, :boolean, :default => false
  end
end
