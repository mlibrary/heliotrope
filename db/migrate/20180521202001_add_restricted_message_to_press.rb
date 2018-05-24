class AddRestrictedMessageToPress < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :restricted_message, :text
  end
end
