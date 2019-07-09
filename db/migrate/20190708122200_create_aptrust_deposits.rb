class CreateAptrustDeposits < ActiveRecord::Migration[5.1]
  def change
    create_table :aptrust_deposits do |t|
      t.string :noid, unique: true, null: false
      t.string :identifier, unique: true, null: false

      t.timestamps
    end
  end
end
