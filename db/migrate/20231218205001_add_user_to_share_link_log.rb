class AddUserToShareLinkLog < ActiveRecord::Migration[5.2]
  def change
    add_column :share_link_logs, :user, :string, after: :press
  end
end
