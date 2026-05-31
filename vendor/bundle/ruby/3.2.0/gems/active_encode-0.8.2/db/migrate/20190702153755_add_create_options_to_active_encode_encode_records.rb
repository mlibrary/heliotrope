# frozen_string_literal: true
class AddCreateOptionsToActiveEncodeEncodeRecords < ActiveRecord::Migration[5.0]
  def change
    add_column :active_encode_encode_records, :create_options, :text
  end
end
