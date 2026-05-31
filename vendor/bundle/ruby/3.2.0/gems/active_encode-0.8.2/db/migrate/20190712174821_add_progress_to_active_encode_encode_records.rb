# frozen_string_literal: true
class AddProgressToActiveEncodeEncodeRecords < ActiveRecord::Migration[5.1]
  def change
    add_column :active_encode_encode_records, :progress, :float
  end
end
