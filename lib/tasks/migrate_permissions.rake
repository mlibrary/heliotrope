# frozen_string_literal: true

desc 'Migrate legacy "permissions" to checkpoint permits.'
namespace :heliotrope do
  task migrate_permissions: :environment do
    puts 'Updating individuals ...'
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
    permission_service = PermissionService.new
    puts 'Migrating...'
    Product.all.each do |product|
      puts "product: #{product.identifier}"
      product.lessees.each do |lessee|
        if lessee.institution?
          puts "institution: #{lessee.identifier}"
          institution = Institution.find_by(identifier: lessee.identifier)
          permission_service.permit_read_access_resource(:institution, institution.id, :product, product.id)
        else
          puts "individual: #{lessee.identifier}"
          individual = Individual.find_by(identifier: lessee.identifier)
          permission_service.permit_read_access_resource(:individual, individual.id, :product, product.id)
        end
      end
    end
    puts 'Migrated.'
  end
end
