class RenameNoidToHandleAndAddUrlValueInHandleDeposits < ActiveRecord::Migration[5.2]
  def change
    rename_column :handle_deposits, :noid, :handle
    add_index :handle_deposits, :handle, unique: true
    add_column :handle_deposits, :url_value, :string, after: :handle
  end
end
