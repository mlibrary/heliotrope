# frozen_string_literal: true

# See FULCRUMOPS-13
# press will include subpresses
# Updated with HELIO-4121
desc "Create a usage report to send to PSI"
namespace :heliotrope do
  task :psi_report, [:press] => :environment do |_t, args|
    # Usage: bundle exec rake "heliotrope:psi_report[michigan]" > /tmp/psi-report.csv

    fail "You must include a press subdomain" unless args.press.present?
    press = Press.where(subdomain: args.press).first
    fail "No Press found for subdomain: #{args.press}" unless press.present?
    presses = press.children.pluck(:id) << press.id

    counter = CounterReport.where(request: 1, press: presses).where("created_at > ?", 6.months.ago)

    # There's some weird stuff where the noid and the parent_noid can be the same (the monograph's)
    # but that currently only happens with Investigations, not Requests, so this should work ok...
    file_sets = presenters_for(Hyrax::FileSetPresenter, counter.pluck(:noid).uniq)
    monographs = presenters_for(Hyrax::MonographPresenter, counter.pluck(:parent_noid).uniq)

    # puts ["Time Stamp", "IP Address", "Monograph Title", "Chapter/Resource Title", "Creators"].to_csv
    puts ["Event Date", "Event", "ISBN/DOI", "Publisher Name", "Book Title/Journal Title", "Author(s)", "Chapter/Article Title", "IP Adress", "OA/Paid"].to_csv

    counter.each do |c|
      ip = c.session.split("|")[0]
      chapter = c.section_type == "Chapter" ? c.section : file_sets[c.noid]&.title 

      puts [
            c.created_at, 
            "request",
            which_doi,
            monographs[c.parent_noid]&.publisher.first,
            monographs[c.parent_noid]&.title,
            monographs[c.parent_noid]&.creator.join("; "),
            chapter,
            ip,
            monographs[c.parent_noid]&.open_access? ? "OA" : "Paid"
      ].to_csv
    end

  end

  def which_doi
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