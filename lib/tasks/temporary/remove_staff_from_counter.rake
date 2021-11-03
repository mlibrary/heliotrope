# frozen_string_literal: true

# HELIO-4090
# Note: We're only removing counter_table rows for staff hits after 2021-07-01 because of
# past reporting concerns, see comment in the ticket.
desc "Remove staff (490) rows from the counter_report table"
namespace :heliotrope do
  task remove_staff_from_counter: :environment do
    start = CounterReport.count
    CounterReport.where(institution: 490).where("created_at >= ?", "2021-07-01").pluck(:session).uniq.each do |session|
      p "destroying #{session}"
      CounterReport.where(session: session).destroy_all
    end
    p "started with #{start} rows, ended with #{CounterReport.count} rows"
  end
end