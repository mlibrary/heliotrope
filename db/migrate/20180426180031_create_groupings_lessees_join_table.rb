class CreateGroupingsLesseesJoinTable < ActiveRecord::Migration[5.1]
  def change
    create_join_table :groupings, :lessees do |t|
      t.references :grouping, foreign_key: true
      t.references :lessee, foreign_key: true
    end
    add_index :groupings_lessees, [:grouping_id, :lessee_id], unique: true
  end
end
