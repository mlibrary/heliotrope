class AddContentWarningInformationToPress < ActiveRecord::Migration[5.2]
  def change
    add_column :presses, :content_warning_information, :text
  end
end
