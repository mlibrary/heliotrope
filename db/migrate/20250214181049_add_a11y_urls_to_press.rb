class AddA11yUrlsToPress < ActiveRecord::Migration[6.0]
  def change
    add_column :presses, :accessibility_webpage_url, :string
    add_column :presses, :accessible_copy_request_form_url, :string
  end
end
