class CreateProducts < ActiveRecord::Migration[5.1]
  def change
    create_table :products do |t|
      t.string :identifier

      t.timestamps
    end
  end
end
