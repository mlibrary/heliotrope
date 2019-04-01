class CreateFedoraNode < ActiveRecord::Migration[5.1]
  def change
    create_table :fedora_nodes do |t|
      t.string :uri, null: false, index: true, unique: true
      t.string :noid, null: false, index: true, unique: true
      t.string :model, null: true
      t.json :jsonld, null: false
    end
  end
end
