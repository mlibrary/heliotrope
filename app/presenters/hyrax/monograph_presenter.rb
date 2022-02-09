# frozen_string_literal: true

module Hyrax
  class MonographPresenter < WorkShowPresenter
    include CommonWorkPresenter
    include CitableLinkPresenter
    include EditionPresenter
    include FeaturedRepresentatives::MonographPresenter
    include OpenUrlPresenter
    include SocialShareWidgetPresenter
    include TitlePresenter
    include TombstonePresenter
    include ActionView::Helpers::UrlHelper

    delegate :date_modified, :date_uploaded, :location, :description,
             :creator_display, :creator_full_name, :contributor,
             :subject, :section_titles, :based_near, :publisher, :date_published, :language,
             :isbn, :license, :copyright_holder, :open_access, :funder, :funder_display, :holding_contact, :has_model,
             :buy_url, :embargo_release_date, :lease_expiration_date, :rights, :series,
             :visibility, :identifier, :doi, :handle, :thumbnail_path, :previous_edition, :next_edition,
             :volume, :oclc_owi, :copyright_year,
             to: :solr_document

    def creator # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
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

    def funder_display?
      solr_document.funder_display.present?
    end

    def date_created
      # Only show the first 4 contiguous digits of this, which is the citation publication date, because...
      # for sorting we also allow `-MM-DD` and, in theory, other digits appended (see MonographIndexer)
      # optionally take a 'c' right next to that, as almost 3000 HEB titles have stuff like c1996 in here
      #
      # wrap this in an array as CitationsBehavior calls `.first` on it, though since we first started using...
      # CitationsBehavior we have copied pretty much all of it into heliotrope so could change that if we wanted to
      Array(solr_document['date_created_tesim']&.first.to_s[/c?[0-9]{4}/])
    end

    def date_created?
      date_created.present?
    end

    def isbn_noformat
      isbns = []
      isbn.each do |isbn|
        isbn_removeformat = isbn.sub(/\(.+\)/, '').strip
        isbns << isbn_removeformat if isbn_removeformat.present?
      end
      isbns
    end

    # Dependent upon CitableLinkPresenter
    def heb_dlxs_link
      return unless heb?
      "https://quod.lib.umich.edu/cgi/t/text/text-idx?c=acls;idno=#{heb_url}"
    end

    def bar_number
      identifier&.find { |i| i[/^bar_number:.*/] }&.gsub('bar_number:', '')&.strip
    end

    def unreverse_names(comma_separated_names)
      forward_names = []
      comma_separated_names.each { |n| forward_names << unreverse_name(n) }
      forward_names
    end

    def unreverse_name(comma_separated_name)
      comma_separated_name.split(',').map(&:strip).reverse.join(' ')
    end

    def authors(include_contributors = true)
      return creator_display if creator_display?
      authorship_names = include_contributors ? [unreverse_names(solr_document.creator), unreverse_names(contributor)] : [unreverse_names(solr_document.creator)]
      authorship_names.flatten.to_sentence(last_word_connector: ' and ')
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

    def press_obj
      Press.find_by(subdomain: subdomain)
    end

    def parent_press_subdomain
      press_obj&.parent&.subdomain
    end

    def press_url # rubocop:disable Rails/Delegate
      press_obj.press_url
    end

    def monograph_tombstone_message
      monograph = Sighrax.from_presenter(self)
      monograph.tombstone_message ||
        monograph.publisher.tombstone_message ||
          Sighrax.platform.tombstone_message(monograph.publisher.name)
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

    def buy_url?
      solr_document.buy_url.present?
    end

    def buy_url
      solr_document.buy_url.first if buy_url?
    end

    def catalog_url
      Rails.application.routes.url_helpers.monograph_catalog_path(id)
    end

    def monograph_coins_title?
      return false unless defined? monograph_coins_title
      monograph_coins_title.present?
    end

    def creators_with_roles
      # Wherein we hopelessly try to make structure out of an unstructured string
      # Used for sending XML to crossref to make DOIs
      creators = []
      solr_document["importable_creator_ss"].split(";").each do |creator|
        # Last, First (Role)
        creator.match(/(.*?),(.*?)\((.*?)\)$/) do |m|
          creators << OpenStruct.new(lastname: m[1].strip, firstname: m[2].strip, role: m[3])
        end && next
        # Last, First
        creator.match(/(.*?),(.*?)$/) do |m|
          creators << OpenStruct.new(lastname: m[1].strip, firstname: m[2].strip, role: "author")
        end && next
        # Last
        creator.match(/(.*?)$/) do |m|
          creators << OpenStruct.new(lastname: m[1].strip, firstname: "", role: "author")
        end && next
      end
      creators
    end

    # HELIO-3346, HELIO-3347: Support for indicators to help users understand
    # what books they have access to and why.
    #
    # @param [Array] allow_product_ids {  current_actor.products.pluck(:id) }
    # @param [Array] allow_read_product_ids {  Sighrax.allow_read_products.pluck(:id) }
    def access_level(actor_product_ids, allow_read_product_ids) # rubocop:disable Metrics/PerceivedComplexity
      # Open Access
      return access_indicators(:open_access)  if /yes/i.match?(solr_document.open_access)
      # Unknown because monograph needs to be reindexed!
      return access_indicators(:unknown)      unless solr_document['products_lsim']
      # Purchased
      return access_indicators(:purchased)    if actor_product_ids && (solr_document['products_lsim'] & actor_product_ids).any?
      # Free
      return access_indicators(:free)         if allow_read_product_ids && (solr_document['products_lsim'] & allow_read_product_ids).any?
      # Unrestricted
      return access_indicators(:unrestricted) if solr_document['products_lsim'].include?(0)
      # Restricted
      access_indicators(:restricted)
    end

    def access_indicators(level)
      case level
      when :open_access
        OpenStruct.new(level:   :open_access,
                       show?:   true,
                       icon_sm: ActionController::Base.helpers.image_tag("open-access.svg", width: "16px", height: "16px", alt: "Open Access"),
                       icon_lg: ActionController::Base.helpers.image_tag("open-access.svg", width: "24px", height: "24px", alt: "Open Access"),
                       text:    ::I18n.t('access_levels.access_level_text.open_access'))
      when :purchased
        OpenStruct.new(level:   :purchased,
                       show?:   true,
                       icon_sm: ActionController::Base.helpers.image_tag("green_check.svg", width: "16px", height: "16px", alt: "Purchased"),
                       icon_lg: ActionController::Base.helpers.image_tag("green_check.svg", width: "24px", height: "24px", alt: "Purchased"),
                       text:    ::I18n.t('access_levels.access_level_text.purchased'))
      when :free
        OpenStruct.new(level:   :free,
                       show?:   true,
                       icon_sm: ActionController::Base.helpers.image_tag("free.svg", width: "38px", height: "16px", alt: "Free", style: "vertical-align: top"),
                       icon_lg: ActionController::Base.helpers.image_tag("free.svg", width: "57px", height: "24px", alt: "Free", style: "vertical-align: bottom"),
                       text:    ::I18n.t('access_levels.access_level_text.free'))
      when :unrestricted
        # "unrestricted" is a Monograph with no Component. The products_lsim field
        # is indexed with a 0. As opposed to "unknown" which has an empty products_lsim
        # field which means the monograph should be reindexed
        OpenStruct.new(level:   :unrestricted,
                       show?:   false,
                       icon_sm: '',
                       icon_lg: '',
                       text:    '')
      when :restricted
        access_options_link = if reader_ebook_id.present?
                                " " + link_to(::I18n.t('access_levels.access_level_text.restricted_access_options'), Rails.application.routes.url_helpers.monograph_authentication_url(id: id))
                              else
                                ''
                              end
        OpenStruct.new(level:   :restricted,
                       show?:   true,
                       icon_sm: ActionController::Base.helpers.image_tag("lock_locked.svg", width: "16px", height: "16px", alt: "Restricted"),
                       icon_lg: ActionController::Base.helpers.image_tag("lock_locked.svg", width: "24px", height: "24px", alt: "Restricted"),
                       text:    ::I18n.t('access_levels.access_level_text.restricted') + access_options_link)
      else
        OpenStruct.new(level:   :unknown,
                       show?:   false,
                       icon_sm: '',
                       icon_lg: '',
                       text:    '')
      end
    end
  end
end
