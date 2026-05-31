# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:aa_inst) do
      Integer :uniqueIdentifier, null: false
      String :organizationName, size: 128, null: false
      Integer :manager
      DateTime :lastModifiedTime, default: Sequel::CURRENT_TIMESTAMP, null: false
      String :lastModifiedBy, size: 64, null: false
      String :dlpsDeleted, size: 1, fixed: true, null: false

      primary_key [:uniqueIdentifier]
    end

    create_table(:aa_network, ignore_index_errors: true) do
      Integer :uniqueIdentifier, null: false
      String :dlpsDNSName, size: 128
      String :dlpsCIDRAddress, size: 18
      Bignum :dlpsAddressStart
      Bignum :dlpsAddressEnd
      String :dlpsAccessSwitch, size: 5, null: false
      String :coll, size: 32
      Integer :inst
      DateTime :lastModifiedTime, default: Sequel::CURRENT_TIMESTAMP, null: false
      String :lastModifiedBy, size: 64, null: false
      String :dlpsDeleted, size: 1, fixed: true, null: false

      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:dlpsAddressStart), 0)
      check Sequel::SQL::BooleanExpression.new(:>=, Sequel::SQL::Identifier.new(:dlpsAddressEnd), 0)
      primary_key [:uniqueIdentifier]

      index [:dlpsAddressEnd], name: :network_dlpsAddressEnd_index
      index [:dlpsAddressStart], name: :network_dlpsAddressStart_index
    end
  end
end

# rubocop:enable Metrics/BlockLength
