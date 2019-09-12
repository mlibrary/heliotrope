class MonographToWorkColumnChange < ActiveRecord::Migration[5.1]
  def change
    rename_column :featured_representatives, :monograph_id, :work_id
  end
end
