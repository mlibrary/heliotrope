class CreateProductNoids < ActiveRecord::Migration[5.1]
  def change
    create_table :product_noids do |t|
      t.string :product
      t.string :noid
    end
    add_index :product_noids, :product
    add_index :product_noids, :noid
    add_index :product_noids, [:product, :noid], unique: true
  end
end
