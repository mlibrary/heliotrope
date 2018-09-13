class AddParentNoidToCounterReports < ActiveRecord::Migration[5.1]
  def change
    add_column :counter_reports, :parent_noid, :string
  end
end
