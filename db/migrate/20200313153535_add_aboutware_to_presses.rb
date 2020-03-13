class AddAboutwareToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :aboutware, :boolean, :default => false
  end
end
