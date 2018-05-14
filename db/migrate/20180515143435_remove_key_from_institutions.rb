class RemoveKeyFromInstitutions < ActiveRecord::Migration[5.1]
  def change
    remove_column :institutions, :key, :string
  end
end
