#Add twitter to presses db
class AddTwitterToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column(:presses, :twitter, :string)
  end
end
