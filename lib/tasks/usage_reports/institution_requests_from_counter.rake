# frozen_string_literal: true

# Using COUNTER data to do un-COUNTERlike things
# Given a Press and start and end dates, it will give Total_Item_Requests
# (a COUNTER5 term, but sort of like "all the things that got downloaded") for
# every institution, per month
desc "institution requests usage report kind of"
namespace :heliotrope do
  task :institution_requests_from_counter, [:subdomain, :starts, :ends] => :environment do |_t, args|
    # Usage: bundle exec rails "heliotrope:institution_requests_from_counter[heb, 2018-01-01, 2019-11-30]" > /tmp/my_report.csv
    start_date = Date.parse(args.starts)
    end_date = Date.parse(args.ends)
    press = Press.where(subdomain: args.subdomain).first
    results = {}

    Greensub::Institution.all.each do |inst|
      this_month = start_date
      results[inst.name] = {}
      until this_month > end_date
        item_month = this_month.strftime("%b") + "-" + this_month.year.to_s
        results[inst.name][item_month] = CounterReport.institution(inst.identifier)
                                                      .requests
                                                      .start_date(this_month.beginning_of_month)
                                                      .end_date(this_month.end_of_month)
                                                      .press(press.id)
                                                      .count
        this_month = this_month.next_month
      end
    end

    output = String.new
    CSV.generate(output) do |csv|
      top = ["Total_Item_Requests for all Institutions for #{press.name} from #{start_date} to #{end_date}"]
      top << 1.upto(results.first[1].keys.length).map{""}
      csv << top.flatten

      dates = [""] + results.first[1].keys
      csv << dates.flatten

      results.each do |inst, dates|
        csv << [inst] + dates.values
      end
    end

    puts output
  end
end
