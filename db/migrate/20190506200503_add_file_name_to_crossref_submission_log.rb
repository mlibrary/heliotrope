class AddFileNameToCrossrefSubmissionLog < ActiveRecord::Migration[5.1]
  def change
    add_column :crossref_submission_logs, :file_name, :string
  end
end
