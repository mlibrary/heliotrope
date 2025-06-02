class AddA11yClaimsBoolsToPress < ActiveRecord::Migration[6.0]
  def change
    add_column :presses, :show_accessibility_metadata, :boolean, after: :accessibility_webpage_url, default: true
    add_column :presses, :show_request_accessible_copy_button, :boolean, after: :show_accessibility_metadata, default: true
  end
end
