class AddInCommonToInstitution < ActiveRecord::Migration[5.2]
  def change
    add_column :institutions, :in_common, :boolean, default: false
  end
end
