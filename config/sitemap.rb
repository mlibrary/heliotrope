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

  Monograph.all.to_a.each do |m|
    next if m.state != "http://fedora.info/definitions/1/0/access/ObjState#active"
    next if m.visibility == "restricted"

    m.ordered_members.to_a.each do |member|
      if member.file_set?
        url = Rails.application.routes.url_helpers.hyrax_file_set_path(member.id)
        add url, lastmod: m.date_modified, priority: 0.5, changefreq: 'monthly'
      end
    end
    url = Rails.application.routes.url_helpers.hyrax_monograph_path(m.id)
    add url, lastmod: m.date_modified, priority: 1, changefreq: 'monthly'
  end
end
