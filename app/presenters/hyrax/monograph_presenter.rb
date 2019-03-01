# frozen_string_literal: true

module Hyrax
  class MonographPresenter < WorkShowPresenter
    include AnalyticsPresenter
    include CitableLinkPresenter
    include OpenUrlPresenter
    include TitlePresenter
    include FeaturedRepresentatives::MonographPresenter
    include ActionView::Helpers::UrlHelper

    attr_accessor :pageviews

    delegate :date_created, :date_modified, :date_uploaded, :location, :description,
             :creator_display, :creator_full_name, :contributor,
             :subject, :section_titles, :based_near, :publisher, :date_published, :language,
             :isbn, :license, :copyright_holder, :open_access, :funder, :holding_contact, :has_model,
             :buy_url, :embargo_release_date, :lease_expiration_date, :rights, :series,
             :visibility, :identifier, :doi, :handle, :thumbnail_path,
             to: :solr_document

    def creator
      # this is the value used in CitationsBehavior, so remove anything after the second comma in a name, like HEB's...
      # author birth/death years etc
      citable_creators = []
      solr_document.creator&.each do |creator|
        citable_creator = creator&.split(',')&.map(&:strip)&.first(2)&.join(', ')
        citable_creators << citable_creator if citable_creator.present?
      end
      citable_creators
    end

    def citations_ready?
      # everything used by Hyrax::CitationsBehavior
      title.present? && creator.present? && location.present? &&
        date_created.first.present? && publisher.first.present?
    end

    def based_near_label
      # wrap this in an array as CitationsBehavior seems to be calling `.first` on it
      Array(location)
    end

    def ordered_section_titles
      # FileSets store their section_title as ActiveTriples::Relation, which does not preserve order.
      # As a result they can't be relied on to give the correct order for their own sections, or sections as a whole.
      # For this reason, we're adding section_titles to the monograph, where all sections are entered manually, giving
      # canonical order (and later spelling etc) for FileSet sections.
      # However, fileset_section_titles will make a useful fallback.
      fileset_section_titles = ordered_member_docs.flat_map(&:section_title).uniq
      manual_monograph_section_titles = solr_document.section_titles
      if manual_monograph_section_titles.present?
        if fileset_section_titles.count != manual_monograph_section_titles.count
          Rails.logger.warn("Monograph #{id} has a section_titles count not matching its FileSets' unique section_titles")
        end
        manual_monograph_section_titles
      else
        fileset_section_titles
      end
    end

    def display_section_titles(section_titles_in)
      section_titles_out = []
      ordered_section_titles.each do |ordered_title|
        section_titles_in.each { |title| section_titles_out << ordered_title if title == ordered_title }
      end
      section_titles_out.blank? ? section_titles_in.to_sentence : section_titles_out.to_sentence
    end

    def creator_display?
      solr_document.creator_display.present?
    end

    def license?
      solr_document.license.present?
    end

    def license_link_content
      # account for any (unexpected) mix of http/https links in config/authorities/licenses.yml
      link_content = solr_document.license.first.sub('http:', 'https:')
      # in-house outlier "All Rights Reserved" value, no icon
      return 'All Rights Reserved' if link_content == 'https://www.press.umich.edu/about/licenses#all-rights-reserved'

      # get term for use as alt text
      term = Hyrax::LicenseService.new.select_active_options.detect { |a| a[1] == link_content }&.first
      term ||= 'Creative Commons License'

      link_content = link_content.sub('licenses', 'l')
      link_content = link_content.sub('publicdomain', 'p')
      link_content = link_content.sub('https://creativecommons', 'https://i.creativecommons') + '80x15.png'
      link_content = '<img alt="' + term + '" style="border-width:0" src="' + link_content + '"/>'
      link_content.html_safe # rubocop:disable Rails/OutputSafety
    end

    def copyright_holder?
      solr_document.copyright_holder.present?
    end

    def holding_contact?
      solr_document.holding_contact.present?
    end

    def open_access?
      open_access&.casecmp('yes')&.zero? || false
    end

    def funder?
      solr_document.funder.present?
    end

    def date_created?
      solr_document.date_created.present?
    end

    def isbn_noformat
      isbns = []
      isbn.each do |isbn|
        isbn_removeformat = isbn.sub(/\(.+\)/, '').strip
        isbns << isbn_removeformat if isbn_removeformat.present?
      end
      isbns
    end

    def heb_id
      solr_document.identifier.find { |e| /^heb[0-9]/ =~ e }
    end

    def heb_id?
      heb_id.present?
    end

    def heb_dlxs_link
      return unless heb_id?
      "https://quod.lib.umich.edu/cgi/t/text/text-idx?c=acls;idno=#{heb_id}"
    end

    def unreverse_names(comma_separated_names)
      forward_names = []
      comma_separated_names.each { |n| forward_names << unreverse_name(n) }
      forward_names
    end

    def unreverse_name(comma_separated_name)
      comma_separated_name.split(',').map(&:strip).reverse.join(' ')
    end

    def authors
      return creator_display if creator_display?
      if subdomain != 'heb'
        [unreverse_names(solr_document.creator), unreverse_names(contributor)].flatten.to_sentence(last_word_connector: ' and ')
      else
        [solr_document.creator, contributor].flatten.join('; ')
      end
    end

    def authors?
      authors.present?
    end

    def subdomain
      Array(solr_document['press_tesim']).first
    end

    def press
      Array(solr_document['press_name_ssim']).first
    end

    def press_url
      Press.find_by(subdomain: subdomain).press_url
    end

    def previous_file_sets_id?(file_sets_id)
      return false unless ordered_file_sets_ids.include? file_sets_id
      ordered_file_sets_ids.first != file_sets_id
    end

    def previous_file_sets_id(file_sets_id)
      return nil unless previous_file_sets_id? file_sets_id
      ordered_file_sets_ids[(ordered_file_sets_ids.find_index(file_sets_id) - 1)]
    end

    def next_file_sets_id?(file_sets_id)
      return false unless ordered_file_sets_ids.include? file_sets_id
      ordered_file_sets_ids.last != file_sets_id
    end

    def next_file_sets_id(file_sets_id)
      return nil unless next_file_sets_id? file_sets_id
      ordered_file_sets_ids[(ordered_file_sets_ids.find_index(file_sets_id) + 1)]
    end

    def monograph_analytics_ids
      ordered_file_sets_ids + [id]
    end

    def pageviews_count
      @pageviews ||= pageviews_by_ids(monograph_analytics_ids)
    end

    def pageviews_over_time_graph_data
      [{ "label": "Total Pageviews", "data": flot_pageviews_over_time(monograph_analytics_ids).to_a.sort }]
    end

    def ordered_file_sets_ids
      return @ordered_file_sets_ids if @ordered_file_sets_ids
      file_sets_ids = []
      ordered_member_docs.each do |doc|
        next if doc['has_model_ssim'] != ['FileSet'].freeze
        next if doc.id == solr_document.representative_id
        next if featured_representatives.map(&:file_set_id).include? doc.id
        file_sets_ids.append doc.id
      end
      @ordered_file_sets_ids = file_sets_ids
    end

    def ordered_member_docs
      return @ordered_member_docs if @ordered_member_docs

      ids = Array(solr_document[Solrizer.solr_name('ordered_member_ids', :symbol)])

      if ids.blank?
        @ordered_member_docs = []
        return @ordered_member_docs
      else
        query_results = ActiveFedora::SolrService.query("{!terms f=monograph_id_ssim}#{solr_document.id}", rows: ids.count)

        docs_hash = query_results.each_with_object({}) do |res, h|
          h[res['id']] = ::SolrDocument.new(res)
        end

        @ordered_member_docs = ids.map { |id| docs_hash[id] }.compact
      end
    end

    def buy_url?
      solr_document.buy_url.present?
    end

    def buy_url
      solr_document.buy_url.first if buy_url?
    end

    def monograph_coins_title?
      return false unless defined? monograph_coins_title
      monograph_coins_title.present?
    end

    def monograph_thumbnail(width = 225)
      if representative_id.present?
        "/image-service/#{representative_id}/full/#{width},/0/default.jpg#{representative_presenter&.image_cache_breaker}"
      else
        thumbnail_path
      end
    end

    # This overrides CC 1.6.2's work_show_presenter.rb which is recursive.
    # Because our FileSets also have respresentative_presenters (I guess that's not normal?)
    # this recursive call from Work -> Arbitrary Nesting of Works -> FileSet never ends.
    # Our PCDM model currently only has Work -> FileSet so this this non-recursive approach should be fine
    def representative_presenter
      return nil if representative_id.blank?
      @representative_presenter ||= Hyrax::PresenterFactory.build_for(ids: [representative_id], presenter_class: Hyrax::FileSetPresenter, presenter_args: current_ability).first
    end

    def representative_alt_text?
      solr_document.representative_id.present?
    end

    # Alt text for cover page/thumbnail. Defaults to first title if not found.
    def representative_alt_text
      rep = representative_presenter
      rep.nil? || rep.alt_text.empty? ? solr_document.title.first : rep.alt_text.first
    end

    def assets?
      ordered_file_sets_ids.present?
    end
  end
end
