# frozen_string_literal: true

class OpenAccessEbookTrustJob < ApplicationJob
  queue_as :ebook_trust
  # HELIO-3701
  # Run via cron on the first day of the month generating stats from the previous month
  def perform(subdomain: nil)
    ActiveRecord::Base.retrieve_connection unless ActiveRecord::Base.connected? # HELIO-3844

    subdomain = subdomain || "michigan"
    press = Press.where(subdomain: subdomain).first

    reports = {}
    reports = institution_reports(press, reports)
    reports = item_master_reports(press, reports)
    reports = usage_report(reports) if january_or_july?

    tmp_zip = zipup(reports)

    OpenAccessEbookTrustMailer.send_report(tmp_zip).deliver_now
  end

  def item_master_reports(press, reports)
    institutions.each do |institution|
      params = CounterReporter::ReportParams.new('ir', {
        institution: institution.identifier,
        start_date: start_date,
        end_date: end_date,
        press: press.id,
        metric_type: 'Total_Item_Requests',
        data_type: 'Book',
        access_type: ['Controlled', 'OA_Gold'],
        access_method: 'Regular'
      })

      result = CounterReporter::ItemReport.new(params).report
      if result.present?
        name = "Item Master Report Total_Item_Requests of #{press.name} for #{institution.name} from #{start_date} to #{end_date}"
        reports[name] = CounterReporterService.csv(result)
      end
    end

    reports
  end

  def institution_reports(press, reports)
    requests = InstitutionReportService.run(args: {
      start_date: start_date,
      end_date: end_date,
      press: press.id,
      institutions: institutions,
      report_type: "request"
    })
    if requests.present?
      name = "Total_Item_Requests for all Institutions for #{press.name} from #{start_date} to #{end_date}"
      output = InstitutionReportService.make_csv(subject: name, results: requests)
      reports[name] = output
    end

    investigations = InstitutionReportService.run(args: {
      start_date: start_date,
      end_date: end_date,
      press: press.id,
      institutions: institutions,
      report_type: "investigation"
    })
    if investigations.present?
      name = "Total_Item_Investigations for all Institutions for #{press.name} from #{start_date} to #{end_date}"
      output = InstitutionReportService.make_csv(subject: name, results: investigations)
      reports[name] = output
    end

    reports
  end

  def zipup(reports)
    tmp_zip = Tempfile.new('fulcrum_ebc_reports_zip')

    Zip::OutputStream.open(tmp_zip) { |zos| }
    Zip::File.open(tmp_zip.path, Zip::File::CREATE) do |zip|
      reports.each do |name, data|
        tmp_report = Tempfile.new
        tmp_report.write(data)
        tmp_report.close
        zip.add(flatten_name(name), tmp_report.path)
        # tmp_report.unlink
      end
    end

    tmp_zip.close
    tmp_zip
  end

  def flatten_name(name)
    name.gsub(/[^0-9A-z.\-]/, '_') + ".csv"
  end

  def start_date
    # First day of last month
    Time.zone.today.at_beginning_of_month.prev_month.to_s
  end

  def end_date
    # Last day of last month
    (Time.zone.today - Time.zone.today.mday).to_s
  end

  def usage_report_start_date
    # First day of month, 6 months ago
    Time.zone.today.at_beginning_of_month.prev_month(6).to_s
  end

  def usage_report(reports)
    # Get royalty usage report for heb, for UMich Press titles from the previous 6 months.
    result = Royalty::UsageReport.new("heb", usage_report_start_date, end_date).report_for_copyholder("University of Michigan Press")
    if result.present? && result[:items].present?
      output = CounterReporterService.csv(result)
      name = "Royalty Usage Report for University of Michigan Press in the Humanities EBook Collection from #{usage_report_start_date} to #{end_date}"
      reports[name] = output
    end
    reports
  end

  def january_or_july?
    Time.zone.now.month == 1 || Time.zone.now.month == 7
  end

  def institutions
    subscribers = []
    Greensub::Product.where("identifier like ?", "ebc_%").each do |product|
      subscribers << product.licensees
    end
    subscribers.flatten.uniq.filter_map { |s| s if s.is_a? Greensub::Institution }
  end
end
