#Add location to presses db
class AddLocationToPresses < ActiveRecord::Migration[5.1]
  def change
    add_column(:presses, :location, :text)
  end
end
