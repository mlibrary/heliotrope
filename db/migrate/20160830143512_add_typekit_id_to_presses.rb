#Add typekit id to presses db
class AddTypekitIdToPresses < ActiveRecord::Migration[4.2]
  def change
    add_column(:presses, :typekit, :string)
  end
end
