class AddIndexToInstitutions < ActiveRecord::Migration[5.1]
  def change
    add_index :institutions, :identifier, unique: true
  end
end
