class AddBookSegmentToCounterReports < ActiveRecord::Migration[6.1]
  def change
    add_column :counter_reports, :book_segment, :integer, after: :section_type
  end
end
