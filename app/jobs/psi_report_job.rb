# frozen_string_literal: true

########################################
## NOTE: THIS IS RUN FROM A CRON JOB! ##
########################################

# HELIO-4361 run on the first of the month for the previous month
# Deliver via SFTP

require 'net/ftp'

class PsiReportJob < ApplicationJob
  def perform(subdomain = "michigan", given_start_date = nil, given_end_date = nil)
    ActiveRecord::Base.retrieve_connection unless ActiveRecord::Base.connected? # HELIO-3844

    subdomain = subdomain || "michigan"
    press = Press.where(subdomain: subdomain).first

    report_time = PsiReport::ReportTime.new(given_start_date, given_end_date)
    csv = build_report(press, report_time)
    file_path = File.join("/", "tmp", "fulcrum_psi_report_#{report_time.start_date}_#{report_time.end_date}.csv")
    File.write(file_path, csv)

    filename = Rails.root.join('config', 'psi_sftp.yml')
    if File.exist? filename
      Rails.logger.info("PSI_REPORT: #{filename} credentials exist, sending #{file_path} via SFTP")
      yaml = YAML.safe_load(File.read(filename))
      psi_sftp = yaml['psi_credentials']

      ftp = Net::FTP.open(psi_sftp["ftp"], username: psi_sftp["user"], password: psi_sftp["password"], ssl: true)
      ftp.put(file_path)
      ftp.close
    else
      Rails.logger.info("PSI_REPORT: #{filename} credentials not present, #{file_path} report not sent")
    end
  end

  def build_report(press, report_time)
    counter = CounterReport.requests
                           .press(press) # will automatically include child presses
                           .start_date(report_time.start_date.to_datetime)
                           .end_date(report_time.end_date.to_datetime)

    # There's some weird stuff where the noid and the parent_noid can be the same (the monograph's)
    # but that currently only happens with Investigations, not Requests, so this should work ok...
    file_sets = presenters_for(Hyrax::FileSetPresenter, counter.pluck(:noid).uniq)
    monographs = presenters_for(Hyrax::MonographPresenter, counter.pluck(:parent_noid).uniq)

    header = ["Event Date",
              "Event",
              "ISBN/DOI",
              "Publisher Name",
              "Book Title/Journal Title",
              "Author(s)",
              "Chapter/Article Title",
              "IP Adress",
              "OA/Paid",
              "Journal Imprint"]

    csv = CSV.generate({}) do |row|
      row << header

      counter.each do |c|
        ip = c.session.split("|")[0]
        chapter = c.section_type == "Chapter" ? c.section : file_sets[c.noid]&.page_title

        row << [
          c.created_at.strftime("%m/%d/%Y %H:%M:%S"),
          "request",
          which_doi(c, monographs, file_sets),
          monographs[c.parent_noid]&.publisher.first,
          monographs[c.parent_noid]&.page_title,
          monographs[c.parent_noid]&.creator.join("; "),
          chapter,
          ip,
          monographs[c.parent_noid]&.open_access? ? "TRUE" : "FALSE",
          "" # leave Journal Imprint blank
        ]
      end
    end

    csv
  end

  def which_doi(c, monographs, file_sets)
    # file_set doi if it exists, otherwise the monograph doi (for epubs and other featured reps), otherwise the monograph isbn(s)
    return file_sets[c.noid]&.doi_url if  file_sets[c.noid]&.doi?
    return monographs[c.parent_noid]&.doi_url if monographs[c.parent_noid]&.doi?
    return monographs[c.parent_noid]&.isbn.join("; ") if monographs[c.parent_noid]&.isbn.present?
    ""
  end

  def presenters_for(hyrax_presenter, noids)
    presenters = {}
    until noids.empty?
      Hyrax::PresenterFactory.build_for(ids: noids.shift(999), presenter_class: hyrax_presenter, presenter_args: nil).map do |p|
        presenters[p.id] = p
      end
    end
    presenters
  end
end


module PsiReport
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
  end
end
