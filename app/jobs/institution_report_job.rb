# frozen_string_literal: true

require 'csv'

class InstitutionReportJob < ApplicationJob
  def perform(args:)
    start_date = Date.parse(args[:start_date])
    end_date = Date.parse(args[:end_date])
    press = Press.find args[:press]
    results = {}

    Greensub::Institution.all.each do |inst|
      this_month = start_date
      results[inst.name] = {}
      until this_month > end_date
        item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
        if args[:report_type] == "request"
          results[inst.name][item_month] = CounterReport.institution(inst.identifier)
                                                        .requests
                                                        .start_date(this_month.beginning_of_month)
                                                        .end_date(this_month.end_of_month)
                                                        .press(press.id)
                                                        .count
        else
          results[inst.name][item_month] = CounterReport.institution(inst.identifier)
                                                        .investigations
                                                        .start_date(this_month.beginning_of_month)
                                                        .end_date(this_month.end_of_month)
                                                        .press(press.id)
                                                        .count
        end
        this_month = this_month.next_month
      end
    end

    report_name = if args[:report_type] == "request"
                    "Total_Item_Requests"
                  else
                    "Total_Item_Investigations"
                  end

    report_heading = "#{report_name} for all Institutions for #{press.name} from #{start_date} to #{end_date}"
    output = make_csv(report_heading, results)

    tmp = Tempfile.new
    tmp.write(output)
    tmp.close

    params = {}
    params[:email] = args[:email]
    params[:report_heading] = report_heading
    params[:csv_file] = tmp
    params[:press] = press.name
    params[:report_name] = report_name
    params[:start_date] = start_date.to_s
    params[:end_date] = end_date.to_s

    ReportMailer.send_report(params).deliver_now
    Rails.logger.info("[INSTITUTION REPORT] emailed #{report_name} to #{args[:email]}")
  end

  def make_csv(subject, results)
    output = CSV.generate do |csv|
      top = ["#{subject}"]
      top << 1.upto(results.first[1].keys.length).map { "" }
      csv << top.flatten

      dates = [""] + results.first[1].keys
      csv << dates.flatten

      results.each do |inst, months|
        csv << [inst] + months.values
      end
    end

    output
  end
end
