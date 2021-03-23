class AddIntervalToPresses < ActiveRecord::Migration[5.2]
  def change
    add_column :presses, :interval, :boolean, :default => false
  end
end
