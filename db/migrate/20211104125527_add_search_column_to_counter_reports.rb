class AddSearchColumnToCounterReports < ActiveRecord::Migration[5.2]
  def change
    add_column :counter_reports, :search, :integer
  end
end
