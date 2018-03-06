class CreateSubscriptions < ActiveRecord::Migration[5.1]
  def change
    create_table :subscriptions do |t|
      t.string :subscriber, index: true, unique: true
      t.string :publication, index: true, unique: true
    end
    add_index :subscriptions, [:subscriber, :publication], unique: true
  end
end
