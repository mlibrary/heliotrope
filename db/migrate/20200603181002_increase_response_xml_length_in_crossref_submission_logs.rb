class IncreaseResponseXmlLengthInCrossrefSubmissionLogs < ActiveRecord::Migration[5.1]
  def change
    change_column :crossref_submission_logs, :response_xml, :mediumtext
  end
end
