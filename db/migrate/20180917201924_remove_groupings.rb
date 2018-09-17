class RemoveGroupings < ActiveRecord::Migration[5.1]
  def up
    drop_table :groupings_lessees
    drop_table :groupings
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
