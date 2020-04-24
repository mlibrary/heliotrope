class CreateRobotrons < ActiveRecord::Migration[5.1]
  def self.up
    create_table :robotrons do |t|
      t.string :ip, null: false, index: true, unique: true
      t.integer :hits, default: 0
      t.timestamps
    end
  end

  def self.down
    drop_table :robotrons
  end
end
