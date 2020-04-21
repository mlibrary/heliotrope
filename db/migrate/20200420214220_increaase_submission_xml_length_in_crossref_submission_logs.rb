class IncreaaseSubmissionXmlLengthInCrossrefSubmissionLogs < ActiveRecord::Migration[5.1]
  def change
    change_column :crossref_submission_logs, :submission_xml, :mediumtext
  end
end
