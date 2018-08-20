# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://fulcrum.org"
# SitemapGenerator::Sitemap.public_path = 'public/sitemaps'
SitemapGenerator::Sitemap.sitemaps_path = 'sitemaps/'

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  # add '/static/donors', changefreq: 'monthly'
  # add '/static/about_daily', changefreq: 'monthly'
  # add '/static/about_project', changefreq: 'monthly'
  # add '/static/rights', changefreq: 'monthly'

  docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph", rows: 100_000)
  docs.each do |d|
    next unless d['visibility_ssi'] == 'open'
    d['file_set_ids_ssim'].each do |fsid|
      fs = ActiveFedora::SolrService.query("{!terms f=id}#{fsid}", rows: 1).first
      next unless fs['visibility_ssi'] == 'open'
      rep = FeaturedRepresentative.where(monograph_id: d['id'], file_set_id: fsid).first
      url = if rep&.kind == 'epub'
              Rails.application.routes.url_helpers.epub_path(fsid)
            else
              Rails.application.routes.url_helpers.hyrax_file_set_path(fsid)
            end
      add url, lastmod: d['date_modified_dtsi'], priority: 0.5, changefreq: 'monthly'
    end
    url = Rails.application.routes.url_helpers.hyrax_monograph_path(d['id'])
    add url, lastmod: d['date_modified_dtsi'], priority: 1, changefreq: 'monthly'
  end
end
