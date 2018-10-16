# frozen_string_literal: true

desc 'Migrate legacy "permissions" to checkpoint permits.'
namespace :heliotrope do
  task migrate_permissions: :environment do
    puts 'Initialize'
    PermissionService.database_initialize!
    puts 'Clear'
    PermissionService.clear_permits_table
    permission_service = PermissionService.new
    puts 'Migrating...'
    Product.all.each do |product|
      puts "product: #{product.identifier}"
      product.lessees.each do |lessee|
        if lessee.institution?
          puts "institution: #{lessee.identifier}"
          permission_service.permit_read_access_resource(:institution, lessee.identifier, :product, product.identifier)
        else
          puts "email: #{lessee.identifier}"
          permission_service.permit_read_access_resource(:email, lessee.identifier, :product, product.identifier)
        end
      end
    end
    puts 'Migrated.'
  end
end
