class ChangePathTypeToTextInAPIRequests < ActiveRecord::Migration[5.1]
  def change
    change_column :api_requests, :path, :text
  end
end
