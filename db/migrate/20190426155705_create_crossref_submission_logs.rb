class CreateCrossrefSubmissionLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :crossref_submission_logs do |t|
      t.string :doi_batch_id
      t.integer :initial_http_status
      t.text :initial_http_message
      t.text :submission_xml
      t.string :status
      t.text :response_xml

      t.timestamps
    end
  end
end
