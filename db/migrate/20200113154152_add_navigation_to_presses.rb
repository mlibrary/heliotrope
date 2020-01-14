class AddNavigationToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :navigation_block, :text
  end
end
