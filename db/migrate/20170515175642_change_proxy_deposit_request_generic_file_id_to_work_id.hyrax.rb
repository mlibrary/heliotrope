# This migration comes from hyrax (originally 20160328222239)
class ChangeProxyDepositRequestGenericFileIdToWorkId < ActiveRecord::Migration[4.2]
  def change
    rename_column :proxy_deposit_requests, :generic_file_id, :generic_id if ProxyDepositRequest.column_names.include?('generic_file_id')
  end
end
