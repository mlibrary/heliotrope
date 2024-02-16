class AddShowIrusStatsToPress < ActiveRecord::Migration[5.2]
  def change
    add_column :presses, :show_irus_stats, :boolean, after: :interval, default: true
  end
end
