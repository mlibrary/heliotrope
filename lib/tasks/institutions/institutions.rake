# frozen_string_literal: true

desc 'A CSV report of all institutions'

namespace :heliotrope do
  task institutions: :environment do
    filename = "/tmp/fulcrum-institutions.csv"
    CSV.open(filename, "w") do |csv|
      csv << ["identifier", "name", "display_name", "site", "ror_id", "entity_id", "updated_at"]
      Greensub::Institution.order(:name).to_a.each do |i|
        puts i.display_name
        csv << [i.identifier, i.name, i.display_name, i.site, i.ror_id, i.entity_id, i.updated_at]
      end
    end
    puts "Wrote to: #{filename}"
  end
end