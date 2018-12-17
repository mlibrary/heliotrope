class CreateShareLinkLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :share_link_logs do |t|
      t.string :ip_address
      t.string :institution
      t.string :press
      t.string :title
      t.string :noid
      t.string :token
      t.string :action

      t.timestamps
    end
  end
end
