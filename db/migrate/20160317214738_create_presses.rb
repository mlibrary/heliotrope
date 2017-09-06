class CreatePresses < ActiveRecord::Migration[4.2]
  def change
    create_table :presses do |t|
      t.string :name
      t.string :logo_path
      t.text :description
      t.string :subdomain

      t.timestamps null: false
    end
  end
end
