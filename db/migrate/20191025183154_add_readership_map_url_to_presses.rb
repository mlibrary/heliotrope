class AddReadershipMapUrlToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column :presses, :readership_map_url, :string
  end
end
