class CreateInstitutions < ActiveRecord::Migration[5.1]
  def change
    create_table :institutions do |t|
      t.string :key
      t.string :name
      t.string :site
      t.string :login

      t.timestamps
    end
  end
end
