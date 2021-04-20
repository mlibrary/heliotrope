class AddTombstoneMessageToPresses < ActiveRecord::Migration[5.2]
  def change
    add_column :presses, :tombstone_message, :text
  end
end
