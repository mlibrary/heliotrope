# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "https://fulcrum.org"

# we want these in the shared directory where they won't get blown away each time
# see https://github.com/kjvarga/sitemap_generator#deployments--capistrano
SitemapGenerator::Sitemap.public_path = 'public/sitemaps'

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

  docs = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND -press_sim:demo", rows: 100_000)
  docs.each do |d|
    next unless d['visibility_ssi'] == 'open'
    d['file_set_ids_ssim'].each do |fsid|
      fs = ActiveFedora::SolrService.query("{!terms f=id}#{fsid}", rows: 1).first
      next unless fs.present? && fs['visibility_ssi'] == 'open'
      rep = FeaturedRepresentative.where(work_id: d['id'], file_set_id: fsid).first

      # "featured representative" file_sets that are not epubs don't need to be in sitemaps
      next if rep&.kind.present? && rep&.kind != 'epub'

      # epubs, if they are not restricted by checkpoint, get a special ereader url.
      # if they are restricted by checkpoint, they shouldn't be in sitemaps since google can't access them
      if rep&.kind == 'epub' && EPubPolicy.new(Anonymous.new({}), Sighrax.factory(fsid)).show?
        url = Rails.application.routes.url_helpers.epub_path(fsid)
        add url, lastmod: d['date_modified_dtsi'], priority: 0.5, changefreq: 'monthly'
        next
      end

      # the majority of FileSets won't be featured reps at all, so get a 'normal' url
      url = Rails.application.routes.url_helpers.hyrax_file_set_path(fsid)
      add url, lastmod: d['date_modified_dtsi'], priority: 0.5, changefreq: 'monthly'
    end
    # monographs are always in sitemaps (unless they're in Draft)
    url = Rails.application.routes.url_helpers.hyrax_monograph_path(d['id'])
    add url, lastmod: d['date_modified_dtsi'], priority: 1, changefreq: 'monthly'
  end
end
