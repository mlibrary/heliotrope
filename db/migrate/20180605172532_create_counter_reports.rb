class CreateCounterReports < ActiveRecord::Migration[5.1]
  def change
    create_table :counter_reports do |t|
      t.string :session
      t.integer :institution
      t.string :noid
      t.string :model
      t.string :section
      t.string :section_type
      t.integer :investigation
      t.integer :request
      t.string :turnaway
      t.string :access_type

      t.timestamps
    end
  end
end
