class CreateFeaturedRepresentatives < ActiveRecord::Migration[5.1]
  def change
    create_table :featured_representatives do |t|
      t.string :monograph_id
      t.string :file_set_id
      t.string :kind

      t.timestamps
    end
  end
end
