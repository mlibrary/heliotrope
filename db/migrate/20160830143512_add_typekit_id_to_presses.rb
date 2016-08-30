#Add typekit id to presses db
class AddTypekitIdToPresses < ActiveRecord::Migration
  def change
    add_column(:presses, :typekit, :string)
  end
end
