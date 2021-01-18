# frozen_string_literal: true

# For HELIO-2488
# HELIO-3118

# Creates a report of handles => dois that will
# be ingested into TMM so that TMM can know the
# handle that Fulcrum has assigned to a Monograph

desc 'monograph handles and DOIs for certain presses'
namespace :heliotrope do
  task fulcrum_published_dois: :environment do
    # You can put child presses here, or not.
    # If you don't it will automatically pick up the children of a press.
    subdomains = [
      'michigan',
      'leverpress',
      'amherst',
      'maizebooks',
      'a2ru',
      'atg',
      'cv',
      'cb',
      'dialogue',
      'barpublishing',
      'lrcss',
      'cjs',
      'csas',
      'cseas',
      'um-pccn'
    ]

    children = []
    subdomains.each do |subdomain|
      children << Press.where(subdomain: subdomain).first&.children&.pluck(:subdomain)
    end

    subdomains = subdomains + children
    subdomains = subdomains.flatten.compact.uniq

    hits = ActiveFedora::SolrService.query("{!terms f=press_sim}#{subdomains.map(&:downcase).join(',')}", rows: 100_000)

    hits.each do |hit|
      next unless hit["suppressed_bsi"] == false && hit["visibility_ssi"] == "open"
      presenter = Hyrax::MonographPresenter.new(SolrDocument.new(hit), nil)
      puts %Q|"#{presenter.handle_url}","#{presenter.doi_url}","#{presenter.subdomain}"|
    end
  end
end
