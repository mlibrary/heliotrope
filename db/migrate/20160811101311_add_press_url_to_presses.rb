#Add press url to presses db
class AddPressUrlToPresses < ActiveRecord::Migration
  def change
    add_column(:presses, :press_url, :string)
    
  end
end
