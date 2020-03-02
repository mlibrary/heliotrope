class CreateHandleDeposits < ActiveRecord::Migration[5.1]
  def change
    create_table :handle_deposits do |t|
      t.string :noid, unique: true, null: false
      t.string :action, null: false, default: 'create'
      t.boolean :verified, default: false

      t.timestamps
    end
  end
end
