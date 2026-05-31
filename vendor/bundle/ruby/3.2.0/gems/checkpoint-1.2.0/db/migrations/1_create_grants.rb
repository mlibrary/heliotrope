# frozen_string_literal: true

Sequel.migration do
  change do
    create_table :grants do
      primary_key :id
      column :agent_type, String, size: 100, null: false
      column :agent_id, String, size: 100, null: false
      column :agent_token, String, size: 201, null: false
      column :credential_type, String, size: 100, null: false
      column :credential_id, String, size: 100, null: false
      column :credential_token, String, size: 201, null: false
      column :resource_type, String, size: 100, null: false
      column :resource_id, String, size: 100, null: false
      column :resource_token, String, size: 201, null: false
      column :zone_id, String, size: 100, null: false
    end
  end
end
