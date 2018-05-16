class AddIndexToComponents < ActiveRecord::Migration[5.1]
  def change
    add_index :components, :handle, unique: true
  end
end
