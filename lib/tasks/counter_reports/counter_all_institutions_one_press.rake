# frozen_string_literal: true

desc 'Create a directory of COUNTER reports for all Institutions for a particular Press'
namespace :heliotrope do
  task :counter_all_institutions_one_press, [:subdomain, :start_date, :end_date] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:counter_all_institutions_one_press[heb, 2018-01-01, 2018-10-31]"
    press_id = Press.where(subdomain: args.subdomain).first.id

    csv_dir = "/tmp/fulcrum-counter-reports/#{Time.now.to_s.gsub!(' ', '_')}"
    FileUtils.mkdir_p(csv_dir)

    Institution.order(:name).to_a.each do |institution|
      params = {
        institution: institution.identifier,
        start_date: args.start_date,
        end_date: args.end_date,
        press: press_id,
        metric_type: ['Total_Item_Requests', 'Unique_Title_Requests'], # this is typical for a TR_B1
        access_type: 'OA_Gold' # this is not
      }
      csv = CounterReporterService.csv(CounterReporterService.tr(params))
      report = File.join(csv_dir, "#{institution.identifier}.csv")
      p "Created report for #{institution.name} at #{report}"
      File.write(report, csv)
    end
  end
end
