# This migration comes from hyrax (originally 20160328222237)
class ChangeProxyDepositGenericFileIdToWorkId < ActiveRecord::Migration[4.2]
  def change
    rename_column :proxy_deposit_requests, :generic_file_id, :work_id
  end
end
