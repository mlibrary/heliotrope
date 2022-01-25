class TwoLogosPerInstitution < ActiveRecord::Migration[5.2]
  def change
    rename_column :institutions, :logo_path, :horizontal_logo
    add_column :institutions, :vertical_logo, :string, after: :horizontal_logo
  end
end
