class AddFieldsToComponentsTable < ActiveRecord::Migration[5.1]
  def change
    add_column :components, :identifier, :string
    add_column :components, :name, :string
    add_column :components, :noid, :string
    add_index :components, :identifier, unique: true
  end
end
