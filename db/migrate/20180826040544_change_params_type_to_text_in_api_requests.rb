class ChangeParamsTypeToTextInAPIRequests < ActiveRecord::Migration[5.1]
  def change
    change_column :api_requests, :params, :text
  end
end
