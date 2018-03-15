class CreateLessees < ActiveRecord::Migration[5.1]
  def change
    create_table :lessees do |t|
      t.string :identifier

      t.timestamps
    end
  end
end
