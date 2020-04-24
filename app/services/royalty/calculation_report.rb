# frozen_string_literal: true

# HELIO-3155

module Royalty
  class CalculationReport
    include Royalty::Reportable
    include ActionView::Helpers::NumberHelper

    def initialize(subdomain, start_date, end_date, total_royalties)
      @subdomain = subdomain
      @press = Press.where(subdomain: @subdomain).first
      @start_date = Date.parse(start_date)
      @end_date = Date.parse(end_date)
      @total_royalties = total_royalties # some 2 place decimal number like 1.76 or 46924.23 or something
    end

    def report
      items = item_report[:items]
      items = update_results(items)
      items = by_monographs(items)

      items = calculate_royalty(items)
      @total_royalty_all_rightsholders = total_royalties_all_rightsholders(items)
      @total_hits_all_rightsholders = total_hits_all_rightsholders(items)
      # make and send reports
      reports = copyholder_reports(items)
      send_reports(reports)
      reports
    end

    private

      def rename_hits_heading(items)
        # Change the column heading 'Hits' to 'Total Title Hits'
        items.each do |item|
          item.transform_keys! { |k| k == "Hits" ? "Total Title Hits" : k }
        end
        items
      end

      def format_royalty(items)
        items.each do |item|
          # no dollar sign so unit: ""
          item["Royalty Earning"] = number_to_currency(item["Royalty Earning"], unit: "")
        end
        items
      end

      def copyholder_reports(all_items)
        reports = {}
        items_by_copyholders(all_items).each do |copyholder, items|
          # HELIO-3330
          rightsholder_hits = items.map { |k| k["Hits"] }.sum
          rightsholder_royalties = items.map { |k| k["Royalty Earning"] }.sum

          items = format_royalty(items)
          items = format_hits(items)
          items = rename_hits_heading(items)

          name = copyholder.gsub(/[^0-9A-z.\-]/, '_') + ".calc.#{@start_date.strftime("%Y%m")}-#{@end_date.strftime("%Y%m")}.csv"
          reports[name] = {
            header: {
              "Collection Name": @press.name,
              "Report Name": "Royalty Calculation Report",
              "Rightsholder Name": copyholder,
              "Reporting Period": "#{@start_date.strftime("%Y%m")} to #{@end_date.strftime("%Y%m")}",
              # Total Hits (All Rights Holders): [total of all Total Item Requests for all content types, regardless of rightsholder, for the period]
              "Total Hits (Non-OA Titles, All Rights Holders)": number_with_delimiter(@total_hits_all_rightsholders),
              # This number will ultimately be the same as the provided @total_royalties param
              # but we'll do the math of adding up the individual royalties as a sort of check
              "Total Royalties Shared (All Rights Holders)": number_to_currency(@total_royalty_all_rightsholders, unit: ""),
              "Rightsholder Hits": number_with_delimiter(rightsholder_hits),
              "Rightsholder Royalties": number_to_currency(rightsholder_royalties, unit: ""),
            },
            items: items
          }
        end
        reports
      end

      def calculate_royalty(items)
        # "Royalty Earning: [ total_royalties ] * [ Hits for this Monograph ] / [total Hits]"
        items.each do |item|
          item["Royalty Earning"] = item["Hits"] * @total_royalties / total_hits_all_rightsholders(items)
        end
        items
      end

      def by_monographs(items)
        return @by_monographs if @by_monographs.present?
        monographs = {}
        # We take the item level report and "condense" it to the monograph level
        # So obviously we can't use a lot of the item level fields.
        items.each do |item|
          noid = item["Parent_Proprietary_ID"]
          if monographs[noid].present?
            monographs[noid]["Hits"] += item["Hits"].to_i
            item.each do |k, v|
              if k.match(/\w{3}-\d{4}/) # match month-year like "Mar-1999"
                monographs[noid][k] += v.to_i
              end
            end
          else
            monographs[noid] = {}
            # # Not sure what Monograph level fields are wanted, maybe this is fine
            monographs[noid]["Parent_Proprietary_ID"] = item["Parent_Proprietary_ID"]
            monographs[noid]["Title"] = item["Parent_Title"]
            monographs[noid]["Authors"] = item["Authors"]
            monographs[noid]["Publisher"] = item["Publisher"]
            monographs[noid]["DOI"] = item["Parent_DOI"]
            monographs[noid]["ISBN"] = item["Parent_ISBN"]
            monographs[noid]["Royalty Earning"] = 0.00  # will calculate this elsewhere
            monographs[noid]["Hits"] = item["Hits"].to_i
            item.each do |k, v|
              if k.match(/\w{3}-\d{4}/)
                monographs[noid][k] = v.to_i
              end
            end
          end
        end

        @by_monographs = monographs.values
      end

      def total_royalties_all_rightsholders(items)
        return @total_royalties_all_rightsholders if @total_royalties_all_rightsholders.present?
        @total_royalties_all_rightsholders = 0.00
        items.each do |item|
          @total_royalties_all_rightsholders += item["Royalty Earning"].to_f
        end
        @total_royalties_all_rightsholders
      end

      def update_results(items)
        items.each do |item|
          # Reporting_Period_Total:
          # Change label to Hits
          item["Hits"] = item.delete("Reporting_Period_Total")
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
          access_type: ['Controlled'],
          access_method: 'Regular'
        })
      end
  end
end
