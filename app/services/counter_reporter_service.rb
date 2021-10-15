# frozen_string_literal: true

class CounterReporterService
  # See notes in HELIO-1376

  def self.pr(params)
    platform_params = CounterReporter::ReportParams.new('pr', params)
    return({ header: platform_params.errors, items: [] }) unless platform_params.validate!
    CounterReporter::PlatformReport.new(platform_params).report
  end

  def self.pr_p1(params)
    # Example pr_p1 report:
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1932253188
    platform_params = CounterReporter::ReportParams.new('pr_p1', params)
    return({ header: platform_params.errors, items: [] }) unless platform_params.validate!
    CounterReporter::PlatformReport.new(platform_params).report
  end

  def self.tr_b1(params)
    # Example tr_b1 report:
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1559300549
    title_params = CounterReporter::ReportParams.new('tr_b1', params)
    return({ header: title_params.errors, items: [] }) unless title_params.validate!
    CounterReporter::TitleReport.new(title_params).report
  end

  def self.tr_b2(params)
    title_params = CounterReporter::ReportParams.new('tr_b2', params)
    return({ header: title_params.errors, items: [] }) unless title_params.validate!
    CounterReporter::TitleReport.new(title_params).report
  end

  def self.tr_b3(params)
    title_params = CounterReporter::ReportParams.new('tr_b3', params)
    return({ header: title_params.errors, items: [] }) unless title_params.validate!
    CounterReporter::TitleReport.new(title_params).report
  end

  def self.tr(params)
    # Example tr report:
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1709631407
    title_params = CounterReporter::ReportParams.new('tr', params)
    return({ header: title_params.errors, items: [] }) unless title_params.validate!
    CounterReporter::TitleReport.new(title_params).report
  end

  def self.ir(params)
    item_params = CounterReporter::ReportParams.new('ir', params)
    return({ header: title_params.errors, items: [] }) unless item_params.validate!
    CounterReporter::ItemReport.new(item_params).report
  end

  def self.ir_m1(params)
    item_params = CounterReporter::ReportParams.new('ir_m1', params)
    return({ header: title_params.errors, items: [] }) unless item_params.validate!
    CounterReporter::ItemReport.new(item_params).report
  end

  def self.csv(report) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    # CSV for COUNTER is just weird and not normal
    # https://docs.google.com/spreadsheets/d/1fsF_JCuOelUs9s_cvu7x_Yn8FNsi5xK0CR3bu2X_dVI/edit#gid=1932253188
    CSV.generate({}) do |csv| # rubocop:disable Metrics/BlockLength
      row = []
      # header rows
      report[:header]&.each do |k, v|
        row << k
        row << v
        1.upto(report[:items][0].length - 2).each do
          row << ""
        end
        csv << row
        row = []
      end
      # empty row
      csv << 1.upto(report[:items][0].length).map { "" } if report[:header].present?
      # items
      if report[:items][0].empty?
        csv << ["Report is empty", ""]
      else
        # item row header
        report[:items][0].each do |k, _|
          row << k
        end
        csv << row
        # item rows
        row = []
        report[:items].each do |item|
          item.each do |_, v|
            row << v
          end
          csv << row
          row = []
        end
      end
    end
  end

  # This COUNTER4 report is sort of it's own thing...
  # See HELIO-2386
  def self.counter4_br2(params)
    params = CounterReporter::ReportParams.new('counter4_br2', params)
    return({ header: params.errors, items: [] }) unless params.validate!
    report = CounterReporter::Counter4BookReport.new(params).report
    CSV.generate({}) do |csv|
      report[:header].each do |row|
        csv << row
      end
      report[:items].each do |row|
        csv << row
      end
    end
  end
end
