# frozen_string_literal: true

require 'net/ftp'

module Royalty
  module Reportable
    extend ActiveSupport::Concern
    include ActionView::Helpers::NumberHelper

    def box_config
      return @box_config if @box_config.present?
      @box_config ||= begin
        filename = Rails.root.join('config', 'box.yml')
        @yaml = YAML.safe_load(File.read(filename)) if File.exist?(filename)
        @yaml ||= {}
        @yaml['lib_ptg_box']
      end
    end

    def send_reports(reports)
      dir = File.join("Library PTG Box", "HEB", "HEB Royalty Reports", "#{@start_date.strftime("%Y-%m")}_to_#{@end_date.strftime("%Y-%m")}")
      ftp = Net::FTP.open(box_config["ftp"], username: box_config["user"], password: box_config["password"], ssl: true)
      begin
        ftp.mkdir(dir)
      rescue Net::FTPPermError => e
        Rails.logger.info "[ROYALTY REPORTS] #{dir} already exists (THIS IS OK!): #{e}"
      end
      ftp.chdir(dir)
      reports.each do |name, report|
        file = Tempfile.new(name)
        file.write(CounterReporterService.csv(report))
        file.close
        ftp.putbinaryfile(file, name)
        file.unlink
        Rails.logger.info("[ROYALTY REPORTS] Put #{name}")
      end
    rescue StandardError => e
      Rails.logger.error "[ROYALTY REPORTS] FTP Error: #{e}\n#{e.backtrace.join("\n")}"
    end

    def format_numbers(items)
      items.each do |item|
        item["Hits"] = number_with_delimiter(item["Hits"])
        item.map { |k, v| item[k] = number_with_delimiter(v) if k.match(/\w{3}-\d{4}/) } # matches "Jan-2019" or whatever
      end
      items
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
