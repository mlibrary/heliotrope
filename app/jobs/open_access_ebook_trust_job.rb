# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

class OpenAccessEbookTrustJob < ApplicationJob
  queue_as :ebook_trust
  # HELIO-3701
  # Run via cron on the first day of the month generating stats from the previous month
  def perform(subdomain = "michigan", given_start_date = nil, given_end_date = nil)
    ActiveRecord::Base.retrieve_connection unless ActiveRecord::Base.connected? # HELIO-3844

    subdomain = subdomain || "michigan"
    press = Press.where(subdomain: subdomain).first

    report_time = OpenAccessEbookTrust::ReportTime.new(given_start_date, given_end_date)

    reports = {}
    reports = institution_reports(report_time, press, reports)
    reports = item_master_reports(report_time, press, reports)
    reports = usage_report(report_time, reports) if report_time.january_or_july?

    zipfile = zipup(reports)

    OpenAccessEbookTrustMailer.send_report(zipfile).deliver_now
  end

  def item_master_reports(report_time, press, reports)
    institutions.each do |institution|
      params = CounterReporter::ReportParams.new('ir', {
        institution: institution.identifier,
        start_date: report_time.start_date,
        end_date: report_time.end_date,
        press: press.id,
        metric_type: 'Total_Item_Requests',
        data_type: ["Book", "Multimedia", "Book_Segment"],
        access_type: ['Controlled', 'OA_Gold'],
        access_method: 'Regular',
        attributes_to_show: ["Authors", "Publication_Date", "Data_Type", "YOP", "Access_Type", "Access_Method"],
        include_parent_details: "true",
        exclude_monthly_details: "false",
        include_monthly_details: "true"
      })

      result = CounterReporter::ItemReport.new(params).report
      if result.present?
        name = "Item Master Report Total_Item_Requests of #{press.name} for #{institution.name} from #{report_time.start_date} to #{report_time.end_date}"
        reports[name] = CounterReporterService.csv(result)
      end
    end

    reports
  end

  def institution_reports(report_time, press, reports)
    requests = InstitutionReportService.run(args: {
      start_date: report_time.start_date,
      end_date: report_time.end_date,
      press: press.id,
      institutions: institutions,
      report_type: "request"
    })
    if requests.present?
      name = "Total_Item_Requests for all Institutions for #{press.name} from #{report_time.start_date} to #{report_time.end_date}"
      output = InstitutionReportService.make_csv(subject: name, results: requests)
      reports[name] = output
    end

    investigations = InstitutionReportService.run(args: {
      start_date: report_time.start_date,
      end_date: report_time.end_date,
      press: press.id,
      institutions: institutions,
      report_type: "investigation"
    })
    if investigations.present?
      name = "Total_Item_Investigations for all Institutions for #{press.name} from #{report_time.start_date} to #{report_time.end_date}"
      output = InstitutionReportService.make_csv(subject: name, results: investigations)
      reports[name] = output
    end

    reports
  end

  def zipup(reports)
    zipfile = File.open(Rails.root.join("tmp", "fulcrum_ebc_reports_zip"), "w")

    Zip::OutputStream.open(zipfile) { |zos| }
    Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
      reports.each do |name, data|
        tmp_report = Tempfile.new
        tmp_report.write(data)
        tmp_report.close
        zip.add(flatten_name(name), tmp_report.path)
        # tmp_report.unlink
      end
    end

    zipfile.close
    zipfile
  end

  def flatten_name(name)
    name.gsub(/[^0-9A-z.\-]/, '_') + ".csv"
  end

  def usage_report(report_time, reports)
    # Get royalty usage report for heb, for UMich Press titles from the previous 6 months.
    result = Royalty::UsageReport.new("heb", report_time.usage_report_start_date, report_time.end_date).report_for_copyholder("University of Michigan Press")
    if result.present? && result[:items].present?
      output = CounterReporterService.csv(result)
      name = "Royalty Usage Report for University of Michigan Press in the Humanities EBook Collection from #{report_time.usage_report_start_date} to #{report_time.end_date}"
      reports[name] = output
    end
    reports
  end

  def institutions
    subscribers = []
    Greensub::Product.where("identifier like ?", "ebc_%").each do |product|
      subscribers << product.licensees
    end
    subscribers.flatten.uniq.filter_map { |s| s if s.is_a? Greensub::Institution }
  end
end

module OpenAccessEbookTrust
  class ReportTime
    attr_reader :given_start_date, :given_end_date

    def initialize(given_start_date = nil, given_end_date = nil)
      raise "given_start_date must be in format YYYY-MM-DD" if given_start_date.present? && !given_start_date.match?(/\d\d\d\d-\d\d-\d\d/)
      raise "given_end_date must be in format YYYY-MM-DD" if given_end_date.present? && !given_end_date.match?(/\d\d\d\d-\d\d-\d\d/)

      @given_start_date = Date.parse(given_start_date) if given_start_date.present?
      @given_end_date = Date.parse(given_end_date) if given_end_date.present?
    end

    def start_date
      # First day of last month
      return @given_start_date.to_s if @given_start_date.present?
      Time.zone.today.at_beginning_of_month.prev_month.to_s
    end

    def end_date
      # Last day of last month
      return @given_end_date.to_s if @given_end_date.present?
      (Time.zone.today - Time.zone.today.mday).to_s
    end

    def usage_report_start_date
      # First day of month, 6 months ago
      return @given_start_date.at_beginning_of_month.prev_month(6).to_s if @given_start_date.present?
      Time.zone.today.at_beginning_of_month.prev_month(6).to_s
    end

    def january_or_july?
      return @given_start_date.month == 1 || @given_start_date.month == 7 if @given_start_date.present?
      Time.zone.now.month == 1 || Time.zone.now.month == 7
    end
  end
end
