# frozen_string_literal: true

require 'net/ftp'

module Royalty
  module Reportable # rubocop:disable Metrics/ModuleLength
    extend ActiveSupport::Concern
    include ActionView::Helpers::NumberHelper

    # No longer using Box, write to disk (/tmp) instead: HELIO-4066
    def send_reports(type, reports)
      dir = File.join("/tmp", type, "#{@start_date.strftime("%Y-%m")}_to_#{@end_date.strftime("%Y-%m")}")
      FileUtils.mkdir_p dir
      reports.each do |name, report|
        file = File.join(dir, name)
        File.write(file, CounterReporterService.csv(report))
        Rails.logger.info("[ROYALTY REPORTS] wrote #{file}")
      end
    rescue StandardError => e
      "[ROYALTY REPORTS] Error: #{e}\n#{e.backtrace.join("\n")}"
    end

    def format_hits(items)
      items.each do |item|
        item["Hits"] = number_with_delimiter(item["Hits"])
        item.map { |k, v| item[k] = number_with_delimiter(v) if k.match?(/\w{3}-\d{4}/) } # matches "Jan-2019" or whatever
      end
      items
    end

    def add_hebids(items)
      items.each_with_index do |item, index|
        monograph_noid = item["Parent_Proprietary_ID"]
        monograph_noid_idx = item.keys.index("Parent_Proprietary_ID")
        items[index] = item.to_a.insert(monograph_noid_idx + 1, ["hebid", hebids[monograph_noid]]).to_h
      end
      items
    end

    def add_copyright_holder_to_combined_report(all_items)
      all_items.each_with_index do |item, index|
        monograph_noid = item["Parent_Proprietary_ID"]
        publisher_idx = item.keys.index("Publisher")
        all_items[index] = item.to_a.insert(publisher_idx + 1, ["Copyright Holder", copyright_holders[monograph_noid]]).to_h
      end
      all_items
    end

    def reclassify_isbns(items)
      # Because of metadata cleanup, we can rely on ISBN formats being strict, like:
      # 9780520047983 (hardcover), 9780520319196 (ebook), 9780520319189 (paper)
      # So this exact matching should always work. Supposedly.
      items.each_with_index do |item, index|
        isbns = item["ISBN"].split(",")
        isbn_idx = item.keys.index("ISBN")

        hardcover = ""
        ebook = ""
        paper = ""
        isbns.each do |isbn|
          hardcover = isbn.gsub(/ \(hardcover\)/, "").strip if isbn.match?(/hardcover/)
          ebook = isbn.gsub(/ \(ebook\)/, "").strip if isbn.match?(/ebook/)
          paper = isbn.gsub(/ \(paper\)/, "").strip if isbn.match?(/paper/)
        end

        new_item =     item.to_a.insert(isbn_idx + 1, ["ebook ISBN", ebook])
        new_item = new_item.to_a.insert(isbn_idx + 2, ["hardcover ISBN", hardcover])
        new_item = new_item.to_a.insert(isbn_idx + 3, ["paper ISBN", paper]).to_h
        new_item.delete("ISBN")
        # remove these from the usage report per HELIO-3572
        new_item.delete("Parent_ISBN")
        new_item.delete("Parent_Print_ISSN")
        new_item.delete("Parent_Online_ISSN")
        items[index] = new_item
      end
      items
    end

    def hebids
      return @hebids if @hebids.present?
      @hebids = {}
      docs = ActiveFedora::SolrService.query("{!terms f=press_sim}#{@subdomain}", fl: ['id', 'identifier_tesim'], rows: 100_000)
      docs.each do |doc|
        identifier = doc['identifier_tesim']&.find { |i| i[/^heb_id:\ heb[0-9].*/] } || ''
        @hebids[doc["id"]] = identifier.split(": ")[1]
      end
      @hebids
    end

    def items_by_copyholders(items)
      return @items_by_copyholders if @items_by_copyholders.present?
      @items_by_copyholders = {}
      items.each do |item|
        this_copyholder = copyright_holders[item["Parent_Proprietary_ID"]]
        @items_by_copyholders[this_copyholder] = [] if @items_by_copyholders[this_copyholder].nil?
        @items_by_copyholders[this_copyholder] << item
      end
      @items_by_copyholders
    end

    def copyright_holders
      return @copyright_holders if @copyright_holders
      @copyright_holders = {}
      docs = ActiveFedora::SolrService.query("{!terms f=press_sim}#{@subdomain}", fl: ['id', 'copyright_holder_tesim'], rows: 100_000)
      docs.each do |doc|
        if doc["copyright_holder_tesim"].blank? || doc["copyright_holder_tesim"].first.blank?
          @copyright_holders[doc["id"]] = "no copyright holder"
        else
          @copyright_holders[doc["id"]] = doc["copyright_holder_tesim"].first
        end
      end
      @copyright_holders
    end

    def total_hits_all_rightsholders(items)
      return @total_hits_all_rightsholders if @total_hits_all_rightsholders.present?
      @total_hits_all_rightsholders = 0
      items.each do |item|
        @total_hits_all_rightsholders += item["Hits"].to_i
      end
      @total_hits_all_rightsholders
    end

    def item_report
      CounterReporter::ItemReport.new(params).report
    end
  end
end
