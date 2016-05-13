class CreateSubBrands < ActiveRecord::Migration
  def change
    create_table :sub_brands do |t|
      t.references :press, index: true, foreign_key: true, null: false
      t.references :parent, index: true, foreign_key: true
      t.string :title, null: false
      t.text :description

      t.timestamps null: false
    end
  end
end
