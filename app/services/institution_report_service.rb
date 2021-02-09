# frozen_string_literal: true

module InstitutionReportService
  def self.run(args:)
    start_date = Date.parse(args[:start_date])
    end_date = Date.parse(args[:end_date])
    press = Press.find args[:press]
    insitutions = args[:institutions] || Greensub::Institution.all
    results = {}

    insitutions.each do |inst|
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

    results
  end

  def self.make_csv(subject:, results:)
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
