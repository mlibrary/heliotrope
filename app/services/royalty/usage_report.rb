# frozen_string_literal: true

# HELIO-2819

module Royalty
  class UsageReport
    include Royalty::Reportable

    def initialize(subdomain, start_date, end_date)
      @subdomain = subdomain
      @press = Press.where(subdomain: @subdomain).first
      @start_date = Date.parse(start_date)
      @end_date = Date.parse(end_date)
    end

    def report
      items = item_report[:items]
      items = update_results(items)

      reports = copyholder_reports(items)
      reports = combined_report(reports, items)
      send_reports(reports)
      reports
    end

    private

      # Generate one additional summary usage report for all rightsholders
      def combined_report(reports, all_items)
        combined = "usage_combined.#{@start_date.strftime("%Y%m")}-#{@end_date.strftime("%Y%m")}.csv"
        reports[combined] = {
          header: {
            "Collection Name": @press.name,
            "Report Name": "Royalty Usage Summary Report",
            "Rightsholder Name": "All Rights Holders",
            "Reporting Period": "#{@start_date.strftime("%Y%m")} to #{@end_date.strftime("%Y%m")}",
            "Total Hits (All Rights Holders)": total_hits_all_rightsholders(all_items).to_s,
          },
          items: all_items
        }
        reports
      end

      def copyholder_reports(all_items)
        reports = {}
        items_by_copyholders(all_items).each do |copyholder, items|
          name = "#{copyholder.split(" ").join("_")}.usage.#{@start_date.strftime("%Y%m")}-#{@end_date.strftime("%Y%m")}.csv"
          reports[name] = {
            header: {
              "Collection Name": @press.name,
              "Report Name": "Royalty Usage Report",
              "Rightsholder Name": copyholder,
              "Reporting Period": "#{@start_date.strftime("%Y%m")} to #{@end_date.strftime("%Y%m")}",
              # Total Hits (All Rights Holders): [total of all Total Item Requests for all content types, regardless of rightsholder, for the period]
              "Total Hits (All Rights Holders)": total_hits_all_rightsholders(all_items).to_s,
            },
            items: items
          }
        end
        reports
      end

      def update_results(items)
        items.each do |item|
          # Reporting_Period_Total:
          # Change label to Hits
          item["Hits"] = item.delete("Reporting_Period_Total")
          # Access_Type: modify the values as follows:
          # OA_Gold -> OA
          # (Controlled can remain Controlled)
          item["Access_Type"] = "OA" if item["Access_Type"] == "OA_Gold"
          # IF ‘Section_Type’ = Chapter: Multiply the value by 25
          if item["Section_Type"] == "Chapter"
            item["Hits"] = item["Hits"].to_i * 25
            item.map { |k, v| item[k] = v.to_i * 25 if k.match(/\w{3}-\d{4}/) } # matches "Jan-2019" or whatever
          end
        end

        items
      end

      def params
        CounterReporter::ReportParams.new('ir', {
          institution: "*",
          start_date: @start_date.to_s,
          end_date: @end_date.to_s,
          press: @press.id,
          metric_type: 'Total_Item_Requests',
          data_type: 'Book',
          access_type: ['Controlled', 'OA_Gold'],
          access_method: 'Regular'
        })
      end
  end
end
