# frozen_string_literal: true

require 'rubygems'
require 'sitemap_generator'

# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = Rails.application.routes.url_helpers.root_url

# HELIO-3953 sitemaps should be uncompressed
# HELIO-4105 sitemaps should be no larger than 5MB
SitemapGenerator::Sitemap.create(compress: false, create_index: true, max_sitemap_links: 20_000) do
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

  # First presses
  Press.all.each do |press|
    next if ['demo', 'heliotrope', 'monitoringservicetarget'].include? press.subdomain
    most_recent_monograph_mod = ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND press_sim:#{press.subdomain}",
                                                                fl: ['date_modified_dtsi'],
                                                                sort: 'date_modified_dtsi desc',
                                                                rows: 1).first&.[]('date_modified_dtsi') || press.updated_at.rfc3339


    url = Rails.application.routes.url_helpers.press_catalog_path(press.subdomain)

    add url, lastmod: most_recent_monograph_mod, priority: 1.0, changefreq: 'monthly'
  end

  # Then monographs and and file_sets
  ActiveFedora::SolrService.query("+has_model_ssim:Monograph AND -(press_sim:demo OR press_sim:heliotrope OR press_sim:monitoringservicetarget)",
                                  fl: ['id',
                                       'date_modified_dtsi',
                                       'visibility_ssi',
                                       'tombstone_ssim',
                                       'representative_id_ssim',
                                       'file_set_ids_ssim'],
                                  rows: 100_000).each do |doc|
    next unless doc['visibility_ssi'] == 'open'
    next if doc['tombstone_ssim']&.first == 'yes'

    file_set_ids = doc['file_set_ids_ssim']
    cover_id = doc['representative_id_ssim']&.first
    rep_file_set_ids = FeaturedRepresentative.where(work_id: doc['id'], file_set_id: file_set_ids).pluck(:file_set_id)

    file_set_docs = []
    # We have books with so many file_sets that the query is too big for solr, so we break them up to manage query size if needed
    if file_set_ids.present?
      until file_set_ids.empty?
        file_set_docs << ActiveFedora::SolrService.query("{!terms f=id}#{file_set_ids.shift(999).join(",")}", fl: ['id', 'visibility_ssi'], rows: 1000)
      end
      file_set_docs = file_set_docs.flatten
    end

    file_set_docs.each do |fs|
      next unless fs.present? && fs['visibility_ssi'] == 'open'
      # Monograph cover and "featured representative" file_set URLs don't need to be in sitemaps.
      # Crawlers cannot parse content from CSB, anyway. They can only read the page title.
      next if fs['id'] == cover_id
      next if rep_file_set_ids.any?(fs['id'])

      # the majority of FileSets won't be featured reps at all, so get a 'normal' url
      url = Rails.application.routes.url_helpers.hyrax_file_set_path(fs['id'])
      add url, lastmod: doc['date_modified_dtsi'], priority: 0.5, changefreq: 'monthly'
    end

    # monographs are always in sitemaps (unless they're in Draft)
    url = Rails.application.routes.url_helpers.hyrax_monograph_path(doc['id'])
    add url, lastmod: doc['date_modified_dtsi'], priority: 1, changefreq: 'monthly'
  end
end
