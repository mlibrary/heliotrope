class DropProductNoidsTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :product_noids
  end

  def down
    fail ActiveRecord::IrreversibleMigration
  end
end
