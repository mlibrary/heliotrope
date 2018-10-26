class AddIndexesToCounterReports < ActiveRecord::Migration[5.1]
  def change
    add_index :counter_reports, :institution
    add_index :counter_reports, :access_type
  end
end
