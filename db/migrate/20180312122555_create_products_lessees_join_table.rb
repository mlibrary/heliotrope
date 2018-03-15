class CreateProductsLesseesJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :products, :lessees do |t|
      t.references :product, foreign_key: true
      t.references :lessee, foreign_key: true
    end
    add_index :lessees_products, [:product_id, :lessee_id], unique: true
  end
end
