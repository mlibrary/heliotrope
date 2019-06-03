class AddDoiCreationToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :doi_creation, :boolean, :default => false
  end
end
