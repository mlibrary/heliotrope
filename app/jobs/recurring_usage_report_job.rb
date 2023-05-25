# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# HELIO-4416
# Right now this is just for BAR but in the future might be expanded
# I think the Settings.recurring_usage_reports would be ok for expansion to
# other presses, but there's going to be logic elsewhere that is BAR specific

class RecurringUsageReportJob < ApplicationJob
  # If you pass all the parameters this can produce reports without configuration
  # but won't email them.
  # If configuration is present in Settings.recurring_usage_reports it will create those
  # reports based on "time_interval" (only "last_weeK" allowed currently) and email them to "to"
  #
  # The use case for this is to run it with a Settings configuration. There is no use case for
  # calling the job with parameters, it's sort of a "just in case".
  # So I'm diabling rubocop's complaints about too many optional params
  def perform(group_key = nil, press = nil, given_start_date = nil, given_end_date = nil) # rubocop:disable Metrics/ParameterLists
    if group_key.present? && press.present? && given_start_date.present? && given_end_date.present?

      report_time = RecurringUsageReport::ReportTime.from_given_dates(given_start_date, given_end_date)
      reports = modified_item_reports(report_time, group_key, press)
      inst_name, inst_report = institution_requests_report(report_time, group_key, press)
      reports[inst_name] = inst_report
      # No email "to" is required so I guess write these out to /tmp instead of emailing them
      reports.each do |name, csv|
        Rails.logger.info("[RecurringUsageReportJob] wrote #{name} to /tmp")
        File.write(File.join(Settings.scratch_space_path, "recurring_usage_reports", "#{name}.csv"), csv)
      end
    elsif Settings.recurring_usage_reports.present?

      Settings.recurring_usage_reports.each do |report|
        group_key = report["group_key"]
        press = report["press"]
        time_interval = report["time_interval"] # only "weekly" is supported right now
        to = report["to"]

        report_time = RecurringUsageReport::ReportTime.from_interval(time_interval)
        reports = modified_item_reports(report_time, group_key, press)
        inst_name, inst_report = institution_requests_report(report_time, group_key, press)
        reports[inst_name] = inst_report
        zipped_reports = zipup(reports)

        RecurringUsageReportMailer.send_report(to, report_time.start_date, report_time.end_date, zipped_reports).deliver_now
      end
    else
      raise "RecurringUsageReportJob needs to be called with valid parameters or a Settings.recurring_usage_reports configuration"
    end
  end

  def institution_requests_report(report_time, group_key, press)
    # BAR didn't specify which kind so we'll do "request" since that's the default
    # We can't use the InstitutionReportService since that only support monthly stats,
    # but what follows is very similar to it.
    results = {}
    subscribers_for_products(group_key).each do |institution|
      results[institution.name] = CounterReport.institution(institution.identifier)
                                               .requests
                                               .where("created_at > ?", report_time.start_date.to_datetime.beginning_of_day)
                                               .where("created_at < ?", report_time.end_date.to_datetime.end_of_day)
                                               .press(Press.where(subdomain: press).first.id)
                                               .count
    end

    csv = CSV.generate do |row|
      row << ["Institution", "Count"]
      if results.present?
        results.each do |name, count|
          row << [name, count]
        end
      else
        row << ["No Results", ""]
      end
    end

    return "Total_Items_All_Institutions_#{today}.csv", csv
  end

  # Like the institution_requests_report above, we can't use any existing COUNTER report code
  # because that only supports monthly stats, and we need weekly.
  def modified_item_reports(report_time, group_key, press)
    reports = {}

    subscribers_for_products(group_key).each do |institution|  # rubocop:disable Metrics/BlockLength
      results = CounterReport.institution(institution.identifier)
                             .requests
                             .where("created_at > ?", report_time.start_date.to_datetime.beginning_of_day)
                             .where("created_at < ?", report_time.end_date.to_datetime.end_of_day)
                             .press(Press.where(subdomain: press).first.id)
                             .where(model: "FileSet")
                             .group('parent_noid', 'noid', 'section', 'access_type')
                             .count

      # That produces this wacky datastructure
      # => {["1831ck45s", "n296wz71s", "I'm a Chapter", "Controlled"]=>22,
      #     ["9g54xj301", "5425kb302", nil, "Controlled"]=>3,
      #     ["qv33rx219", "qn59q4627", nil, "Controlled"]=>1,
      #     ...
      #    }
      # Which is annoying to work with but kind of great that it gets the hit counts.
      # Below we put the structure into a shape that's maybe a little easier to work with

      monograph_results = {}
      monograph_noids = []
      file_set_noids = []
      results.each do |k, v|
        monograph_results[k[0]] = [] if monograph_results[k[0]].blank?
        monograph_results[k[0]] << { noid: k[1], section: k[2], access_type: k[3], count: v }
        monograph_noids << k[0]
        file_set_noids << k[1]
      end

      # There's some weird stuff where the noid and the parent_noid can be the same (the monograph's)
      # but that currently only happens with Investigations, not Requests, so this should work ok...
      monograph_presenters = presenters_for(Hyrax::MonographPresenter, monograph_noids.uniq)
      file_set_presenters = presenters_for(Hyrax::FileSetPresenter, file_set_noids.uniq)

      header = [
        "Authors",
        "Publication_Date",
        "DOI",
        "Parent_Title",
        "Parent_DOI",
        "Component_Title",
        "Data_Type",
        "YOP",
        "Access_Type",
        "Reporting_Period_Total"
      ]

      csv = CSV.generate({}) do |row|
        row << header

        monograph_presenters.values.sort_by(&:page_title).each do |monograph_presenter|
          monograph_results[monograph_presenter.id].each do |counter|
            file_set_presenter = file_set_presenters[counter[:noid]]
            # These values are going to be pretty close to a counter Item report, but maybe not quite
            row << [
              find_authors(file_set_presenter, monograph_presenter),
              file_set_presenter.date_created.first || monograph_presenter.date_created.first,
              file_set_presenter.doi,
              monograph_presenter.page_title,
              monograph_presenter.doi,
              counter[:section],
              find_data_type(counter, file_set_presenter),
              monograph_presenter.date_created.first,
              counter[:access_type],
              counter[:count]
            ]
          end
        end
      end

      name = "#{institution.name.gsub(/[^0-9A-z.\-]/, '_')}_#{today}.csv"
      reports[name] = csv
    end

    reports
  end

  def find_authors(file_set_presenter, monograph_presenter)
    return file_set_presenter&.creator&.join(";") if file_set_presenter&.creator.present?
    return monograph_presenter.authors if monograph_presenter.authors.present?
    ""
  end

  def find_data_type(counter, file_set_presenter)
    return "Book_Segment" if counter["section"].present?
    return "Mulitmedia" if file_set_presenter.multimedia?
    "Book"
  end

  def subscribers_for_products(group_key)
    institutions = []
    Greensub::Product.where(group_key: group_key).each do |product|
      product.institutions.each do |institution|
        institutions << institution
      end
    end

    institutions.uniq
  end

  def today
    Time.zone.now.strftime("%Y-%m-%d")
  end

  def presenters_for(hyrax_presenter, noids)
    presenters = {}
    until noids.empty?
      # 1000 is the limit for the Hyrax factory
      Hyrax::PresenterFactory.build_for(ids: noids.shift(999), presenter_class: hyrax_presenter, presenter_args: nil).map do |p|
        presenters[p.id] = p
      end
    end
    presenters
  end

  def zipup(reports)
    zipfile = File.open(File.join(Settings.scratch_space_path, "recurring_reports_#{today}_zip"), "w")

    # HELIO-4388 Hold tempfiles outside of the zip processes so they aren't
    # garbage collected before they are used.
    tmp_files = []

    Zip::OutputStream.open(zipfile) { |zos| }
    Zip::File.open(zipfile.path, Zip::File::CREATE) do |zip|
      reports.each do |name, data|
        tmp_report = Tempfile.new
        tmp_files << tmp_report
        tmp_report.write(data)
        tmp_report.close
        zip.add(name, tmp_report.path)
      end
    end

    zipfile.close

    # Once fully done, explictly delete the tempfiles
    tmp_files.each do |file|
      file.unlink
    end

    zipfile
  end
end

module RecurringUsageReport
  class ReportTime
    attr_reader :given_start_date, :given_end_date
    private_class_method :new

    def self.from_interval(time_interval)
      # On Sunday morning set a cron to call this.
      # It will create reports from the previous Sunday 12:00am until Saturday 11:59:59.
      # So 7 days ago until yesterday
      # See HELIO-4416
      if time_interval == "last_week"
        new(7.days.ago.strftime("%Y-%m-%d"), 1.day.ago.strftime("%Y-%m-%d"))
      else
        raise "Only time_intervals of 'last_week' accepted, you gave: #{time_interval}"
      end
    end

    def self.from_given_dates(given_start_date, given_end_date)
      raise "given_start_date must be in format YYYY-MM-DD" if given_start_date.present? && !given_start_date.match?(/\d\d\d\d-\d\d-\d\d/)
      raise "given_end_date must be in format YYYY-MM-DD" if given_end_date.present? && !given_end_date.match?(/\d\d\d\d-\d\d-\d\d/)

      new(given_start_date, given_end_date)
    end

    def start_date
      @given_start_date
    end

    def end_date
      @given_end_date
    end

    private

      def initialize(given_start_date, given_end_date)
        @given_start_date = given_start_date
        @given_end_date = given_end_date
      end
  end
end
