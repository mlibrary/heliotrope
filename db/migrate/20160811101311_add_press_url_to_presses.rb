#Add press url to presses db
class AddPressUrlToPresses < ActiveRecord::Migration[4.2]
  def change
    add_column(:presses, :press_url, :string)
    
  end
end
