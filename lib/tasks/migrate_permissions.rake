# frozen_string_literal: true

desc 'Migrate legacy "permissions" to checkpoint permits.'
namespace :heliotrope do
  task migrate_permissions: :environment do
    puts "Updating ..."
    puts 'Components ...'
    Component.all.each do |component|
      puts "component: #{component.handle}"
      noid = HandleService.noid(component.handle)
      entity = Sighrax.factory(noid)
      component.identifier = noid || component.id
      component.name = entity.title
      component.noid = noid
      component.save
    end
    puts 'Individuals ...'
    Lessee.all.each do |lessee|
      next if lessee.institution?
      puts "individual: #{lessee.identifier}"
      individual = Individual.find_or_create_by(email: lessee.identifier)
      individual.identifier = lessee.identifier
      individual.name = lessee.identifier
      individual.save
    end
    puts 'Updated.'
    puts 'Initialize database'
    PermissionService.database_initialize!
    puts 'Clear permits table'
    PermissionService.clear_permits_table
    puts 'Migrating...'
    agent_factory = Checkpoint::Agent
    resource_factory = Checkpoint::Resource
    permission_read = Checkpoint::Credential::Permission.new(:read)
    Product.all.each do |product|
      puts "product: #{product.identifier}"
      product.lessees.each do |lessee|
        if lessee.institution?
          puts "institution: #{lessee.identifier}"
          institution = Institution.find_by(identifier: lessee.identifier)
          # PermissionService.permit_read_access_resource(:institution, institution.id, :product, product.id)
          Checkpoint::DB::Permit.from(agent_factory.from(institution), permission_read, resource_factory.from(product), zone: Checkpoint::DB::Permit.default_zone).save
        else
          puts "individual: #{lessee.identifier}"
          individual = Individual.find_by(identifier: lessee.identifier)
          # PermissionService.permit_read_access_resource(:individual, individual.id, :product, product.id)
          Checkpoint::DB::Permit.from(agent_factory.from(individual), permission_read, resource_factory.from(product), zone: Checkpoint::DB::Permit.default_zone).save
        end
      end
    end
    puts 'Migrated.'
  end
end
