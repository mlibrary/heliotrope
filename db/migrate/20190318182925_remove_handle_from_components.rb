class RemoveHandleFromComponents < ActiveRecord::Migration[5.1]
  def change
    remove_index :components, :handle
    remove_column :components, :handle, :string
    add_index :components, :noid, unique: true
  end
end
