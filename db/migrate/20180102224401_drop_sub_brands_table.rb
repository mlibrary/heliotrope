class DropSubBrandsTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :sub_brands do |t|
      # RE: 'type' see https://stackoverflow.com/a/45825566/3418063
      t.references :press, type: :integer, index: true, foreign_key: true, null: false
      t.integer :parent_id, index: true
      t.string :title, null: false
      t.text :description

      t.timestamps null: false
    end
  end
end
