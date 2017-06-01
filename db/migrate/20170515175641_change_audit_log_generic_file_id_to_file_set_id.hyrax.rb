# This migration comes from hyrax (originally 20160328222238)
class ChangeAuditLogGenericFileIdToFileSetId < ActiveRecord::Migration[4.2]
  def change
    rename_column :checksum_audit_logs, :generic_file_id, :file_set_id unless ChecksumAuditLog.column_names.include?('file_set_id')
  end
end
