class CreateFedoraContain < ActiveRecord::Migration[5.1]
  def change
    create_table :fedora_contains do |t|
      t.string :uri, null: false, index: true, unique: true
      t.string :noid, null: false, index: true, unique: true
      t.string :model, null: true
      t.string :title, null: true
      t.references :fedora_node, null: false, unique: true, foreign_key: true
    end
  end
end
