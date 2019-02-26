# frozen_string_literal: true

# For HELIO-2488

desc 'All published michigan monograph DOIs'
namespace :heliotrope do
  task michigan_published_dois: :environment do
    press = Press.where(subdomain: 'michigan').first
    children = press.children.pluck(:subdomain)
    presses = children.push(press.subdomain).uniq
    hits = ActiveFedora::SolrService.query("{!terms f=press_sim}#{presses.map(&:downcase).join(',')}", rows: 100_000)

    hits.each do |hit|
      next unless hit["suppressed_bsi"] == false && hit["visibility_ssi"] == "open"
      presenter = Hyrax::MonographPresenter.new(SolrDocument.new(hit), nil)
      puts %Q|"#{presenter.handle_url}","#{presenter.doi_url}"|
    end
  end
end
