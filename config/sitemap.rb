# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://fulcrum.org"

# we want these in the shared directory where they won't get blown away each time
# see https://github.com/kjvarga/sitemap_generator#deployments--capistrano
SitemapGenerator::Sitemap.public_path = 'public/sitemaps'

# HELIO-3953 sitemaps should be uncompressed
SitemapGenerator::Sitemap.create(compress: false) do
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

  monograph_docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND -(press_sim:demo OR press_sim:heliotrope OR press_sim:monitoringservicetarget)", rows: 100_000)
  monograph_docs.each do |mono_doc|
    monograph = Hyrax::MonographPresenter.new(SolrDocument.new(mono_doc), nil)
    next unless monograph.visibility == "open"

    # Monographs are always in sitemaps (unless they're in Draft)
    # Open Access monograph need to be differentiated for google scholar, HELIO-4030
    oa_marker = monograph.open_access? ? "oa-monograph" : "monograph"
    url = Rails.application.routes.url_helpers.hyrax_monograph_path(monograph.id, oa_marker: oa_marker)
    add url, lastmod: monograph.date_modified.to_s, priority: 1, changefreq: 'monthly'

    monograph.ordered_member_docs.each do |file_set_doc|
      file_set = Hyrax::FileSetPresenter.new(file_set_doc, nil)

      next unless file_set.visibility == "open"
      # Featured Representative file_set pages don't need to be in sitemaps, nor is there any point adding links...
      # to a complex, JS-dependent `/epub` CSB view, as the crawler sees nothing there to index but the page title.
      next if file_set.featured_representative?

      url = Rails.application.routes.url_helpers.hyrax_file_set_path(file_set.id)
      add url, lastmod: file_set.date_modified.to_s, priority: 0.5, changefreq: 'monthly'
    end
  end
end
