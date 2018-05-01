class CreateGroupings < ActiveRecord::Migration[5.1]
  def change
    create_table :groupings do |t|
      t.string :identifier

      t.timestamps
    end
  end
end
