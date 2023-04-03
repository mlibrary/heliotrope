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
    file_path = File.join("/", "tmp", "fulcrum_#{subdomain}_psi_report_#{report_time.start_date}_#{report_time.end_date}.ready.csv")
    File.write(file_path, csv)

    config = Rails.root.join('config', 'psi_sftp.yml')
    if File.exist? config
      Rails.logger.info("PSI_REPORT: #{config} credentials exist, sending #{file_path} via SFTP")
      yaml = YAML.safe_load(File.read(config))
      psi_sftp = yaml['psi_credentials']

      ftp = Net::FTP.open(psi_sftp["ftp"], username: psi_sftp["user"], password: psi_sftp["password"], ssl: true)
      ftp.put(file_path)
      ftp.close
    else
      Rails.logger.info("PSI_REPORT: #{config} credentials not present, #{file_path} report not sent")
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
              "Journal Imprint",
              "Orcid ID",
              "Affiliation",
              "Funders"]

    csv = CSV.generate({}) do |row|
      row << header

      counter.each do |c|
        ip = c.session.split("|")[0]
        chapter = c.section_type == "Chapter" ? c.section : file_sets[c.noid]&.page_title

        row << [
          c.created_at.strftime("%Y-%m-%d %H:%M:%S"),
          "request",
          which_doi(c, monographs, file_sets),
          monographs[c.parent_noid]&.publisher&.first,
          monographs[c.parent_noid]&.page_title,
          creators(monographs[c.parent_noid]),
          chapter,
          ip,
          monographs[c.parent_noid]&.open_access? ? "TRUE" : "FALSE",
          monographs[c.parent_noid]&.publisher&.first, # HELIO-4422 Journal Imprint is the same as Publisher Namek
          orcids(monographs[c.parent_noid]),
          "", # Affiliation
          "" # Funder ID
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

  def creators(presenter)
    return "" if presenter&.creator.blank?
    presenter.creator.join(";") # no spaces per the example in HELIO-4361
  end


  def orcids(presenter)
    return "" if presenter&.creator_orcids.blank?
    presenter.creator_orcids.join(";")
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
