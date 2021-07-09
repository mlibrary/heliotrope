# frozen_string_literal: true

# See FULCRUMOPS-13
# press will include subpresses
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

    puts ["Time Stamp", "IP Address", "Monograph Title", "Chapter/Resource Title", "Creators"].to_csv

    counter.each do |c|
      ip = c.session.split("|")[0]
      chapter = c.section_type == "Chapter" ? c.section : file_sets[c.noid]&.title

      puts [c.created_at, ip, monographs[c.parent_noid]&.title, chapter, monographs[c.parent_noid]&.authors].to_csv
    end

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