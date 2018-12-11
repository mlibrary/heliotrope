# frozen_string_literal: true

module SystemSpecHelper
  def setup_current_institution(institution)
    db = Keycard::DB.initialize!
    db.execute "delete from aa_network"
    db.execute "delete from aa_inst"

    db.execute <<~SQL
      insert into aa_network
        (uniqueIdentifier, dlpsCIDRAddress, dlpsAddressStart, dlpsAddressEnd, dlpsAccessSwitch, inst, lastModifiedBy, dlpsDeleted)
      values
        ("#{institution.identifier}", '127.0.0.1/32', '2130706433', '2130706433', 'allow', "#{institution.identifier}", 'root', 'f')
    SQL

    db.execute <<~SQL
      insert into aa_inst
        (uniqueIdentifier, organizationName, manager, lastModifiedBy, dlpsDeleted)
      values
        ("#{institution.identifier}", 'Local Host', '0', 'root', 'f')
    SQL
  end

  def teardown_current_institution
    db = Keycard::DB.initialize!
    db.execute "delete from aa_network"
    db.execute "delete from aa_inst"
  end
end
