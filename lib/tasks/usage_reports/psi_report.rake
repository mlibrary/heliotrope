# frozen_string_literal: true

# See FULCRUMOPS-13
# press will include subpresses
# Updated with HELIO-4121
# Updated with HELIO-4361
desc "Create a usage report to send to PSI"
namespace :heliotrope do
  task :psi_report, [:press, :start_date, :end_date] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:psi_report[michigan]"
    # OR
    # Usage: bundle exec rake "heliotrope:psi_report[michigan, 2022-01-01, 2022-01-30]"

    # start_date and end_date are optional
    # Without them, the report will run for the previous month
    # The report is placed in /tmp and delivered via sftp
    # See the PsiReportJob for details.

    PsiReportJob.perform_later(args.press, args.start_date, args.end_date)
  end
end