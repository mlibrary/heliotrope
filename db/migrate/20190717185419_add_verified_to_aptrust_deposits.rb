class AddVerifiedToAptrustDeposits < ActiveRecord::Migration[5.1]
  def change
    add_column :aptrust_deposits, :verified, :boolean, default: false
  end
end
