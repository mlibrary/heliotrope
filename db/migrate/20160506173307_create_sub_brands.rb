class CreateSubBrands < ActiveRecord::Migration
  # Altered this migration in place 2016-08-04.  Blame grosscol.
  def change
    create_table :sub_brands do |t|
      t.references :press, index: true, foreign_key: true, null: false
      t.integer :parent_id, index: true
      t.string :title, null: false
      t.text :description

      t.timestamps null: false
    end
  end
end
