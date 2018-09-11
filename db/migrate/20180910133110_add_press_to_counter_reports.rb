class AddPressToCounterReports < ActiveRecord::Migration[5.1]
  def change
    add_column :counter_reports, :press, :integer
  end
end
