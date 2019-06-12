# frozen_string_literal: true

desc 'One-time fix for counter_report data, see HELIO-2779'
namespace :heliotrope do
  task counter_report_access_type_fixup: :environment do
    change = 0
    no_change = 0
    CounterReport.where("created_at > ?", "2019-03-27").where(access_type: "OA_Gold").each do |row|
      # parent_noid is always the Monograph noid, even if the noid is *also* the monograph noid
      if Greensub::Component.find_by(noid: row.parent_noid)
        row.access_type = "Controlled"
        row.save!
        puts "Fixed #{row.created_at}\t#{row.noid}"
        change += 1
      else
        no_change += 1
      end
    end
    puts "Changed #{change} rows"
    puts "Unchanged #{no_change} rows"
  end
end
