# frozen_string_literal: true

module SystemSpecHelper
  def setup_current_institution(institution)
    db = Keycard::DB.initialize!
    db.execute "delete from aa_network"
    db.execute "delete from aa_inst"

    db.execute <<~SQL.squish
      insert into aa_network
        (uniqueIdentifier, dlpsCIDRAddress, dlpsAddressStart, dlpsAddressEnd, dlpsAccessSwitch, inst, lastModifiedBy, dlpsDeleted)
      values
        ("#{institution.identifier}", '127.0.0.1/32', '2130706433', '2130706433', 'allow', "#{institution.identifier}", 'root', 'f')
    SQL

    db.execute <<~SQL.squish
      insert into aa_inst
        (uniqueIdentifier, organizationName, manager, lastModifiedBy, dlpsDeleted)
      values
        ("#{institution.identifier}", 'Local Host', '0', 'root', 'f')
    SQL
  end

  # Creating a Greensub::Component for a Monograph is not, on its own, enough to restrict it. The
  # Component has to belong to a Greensub::Product that the current actor has no license for.
  # MonographIndexer indexes a Component with no Products as `products_lsim: [0]`, i.e. "unrestricted".
  # Pushing a Product onto the Component also reindexes the Monograph so that `products_lsim` is correct.
  def restrict_monograph!(noid)
    entity = Sighrax.from_noid(noid)
    component = Greensub::Component.create!(identifier: entity.resource_token, name: entity.title, noid: entity.noid)
    component.products << FactoryBot.create(:product)
    component
  end

  def teardown_current_institution
    db = Keycard::DB.initialize!
    db.execute "delete from aa_network"
    db.execute "delete from aa_inst"
  end
end
