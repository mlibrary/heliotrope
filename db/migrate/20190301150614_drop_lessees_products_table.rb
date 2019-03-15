class DropLesseesProductsTable < ActiveRecord::Migration[5.1]
  def up
    drop_table :lessees_products
    drop_table :lessees
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
