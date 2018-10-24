class CreateIndividuals < ActiveRecord::Migration[5.1]
  def change
    create_table :individuals do |t|
      t.string :identifier
      t.string :name
      t.string :email

      t.timestamps
    end
    add_index :individuals, :identifier, unique: true
    add_index :individuals, :email, unique: true
  end
end
