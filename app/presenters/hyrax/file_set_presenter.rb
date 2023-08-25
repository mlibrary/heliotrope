# frozen_string_literal: true

module Hyrax
  class FileSetPresenter # rubocop:disable Metrics/ClassLength
    include TitlePresenter
    include CitableLinkPresenter
    include EmbedCodePresenter
    include OpenUrlPresenter
    include ModelProxy
    include PresentsAttributes
    include CharacterizationBehavior
    include WithEvents
    include FeaturedRepresentatives::FileSetPresenter
    include TombstonePresenter
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TagHelper
    include Skylight::Helpers

    attr_accessor :solr_document, :current_ability, :request, :monograph_presenter, :file_set

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    instrument_method
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?, :eps?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    delegate :resource_type, :caption, :alt_text, :description, :rightsholder,
             :content_type, :creator, :creator_full_name, :contributor, :date_created,
             :keyword, :publisher, :language, :date_uploaded,
             :rights_statement, :license, :embargo_release_date, :lease_expiration_date, :depositor, :tags,
             :title_or_label, :section_title, :content_warning, :content_warning_information,
             :allow_download, :allow_hi_res, :copyright_status, :rights_granted,
             :exclusive_to_platform, :identifier, :permissions_expiration_date,
             :allow_display_after_expiration, :allow_download_after_expiration, :credit_line,
             :holding_contact, :external_resource_url, :primary_creator_role,
             :display_date, :sort_date, :transcript, :translation, :file_format,
             :label, :has_model, :date_modified, :visibility,
             :closed_captions, :visual_descriptions, :article_creator, :article_permalink, :article_issue,
             :article_display_date, :article_title, :article_volume,
             to: :solr_document

    def monograph_id
      Array(solr_document['monograph_id_ssim']).first
    end

    def parent
      @parent_presenter ||= fetch_parent_presenter
    end

    def subjects
      parent.subject
    end

    def previous_id?
      parent.previous_file_sets_id? id
    end

    def previous_id
      parent.previous_file_sets_id id
    end

    def next_id?
      parent.next_file_sets_id? id
    end

    def next_id
      parent.next_file_sets_id id
    end

    def link_name
      current_ability.can?(:read, id) ? Array(solr_document['label_tesim']).first : 'File'
    end

    def multimedia?
      # currently just need this for COUNTER reports
      audio? || video? || image? || eps?
    end

    def external_resource?
      external_resource_url.present?
    end

    def tombstone?
      Sighrax.from_presenter(self).tombstone?
    end

    def allow_high_res_display?
      if tombstone?
        allow_display_after_expiration&.downcase == 'high-res'
      else
        allow_hi_res&.downcase == 'yes'
      end
    end

    def unreverse_names(comma_separated_names)
      forward_names = []
      comma_separated_names.each { |n| forward_names << unreverse_name(n) }
      forward_names
    end

    def unreverse_name(comma_separated_name)
      comma_separated_name.split(',').map(&:strip).reverse.join(' ')
    end

    def article_authors
      # We want the same data entry/UI/CSV file behavior for article_creator as regular creator/contributor fields,
      # i.e. multi-valued ActiveFedora fields where we only use the first value, and separate name entries within...
      # that one with newlines. The splitting here is done in the indexers for the regular creator/contributor fields,
      # for historical reasons. Those values are used in so many places in so many ways.
      authorship_names = [unreverse_names(solr_document.article_creator&.first&.split(/\r?\n/)&.reject(&:blank?)&.map(&:strip))]
      authorship_names.flatten.join(', ')
    end

    def article_creators
      article_creator.join(", ")
    end

    def article_resource?
      article_title.present?
    end

    def article_volume_issue_date
      # HELIO-4383
      if article_issue.present? && article_volume.blank?
        "#{article_issue}, #{article_display_date}"
      elsif article_issue.blank? && article_volume.present?
        "#{article_volume}, #{article_display_date}"
      elsif article_issue.present? && article_volume.present?
        "#{article_volume}, #{article_issue}, #{article_display_date}"
      else
        article_display_date
      end
    end

    # Technical Metadata
    def width
      solr_document['width_is']
    end

    def height
      solr_document['height_is']
    end

    def interactive_map?
      /^interactive map$/i.match?(resource_type.first)
    end

    def mime_type
      solr_document['mime_type_ssi']
    end

    def file_size
      solr_document['file_size_lts']
    end

    def last_modified
      solr_document['date_modified_dtsi']
    end

    def original_checksum
      solr_document['original_checksum_ssim']
    end

    def browser_cache_breaker
      # using the Solr doc's timestamp even though it'll change on any metadata update.
      # More file-specific fields on the Solr doc can't be trusted to be ordered in a useful way on "reversioning".
      # An alternative could be to pull the timestamp from the Hydra Derivatives thumbnail itself, for files that...
      # actually get one, of course.
      # Since we already have the FileSet solr doc, using the solr timestamp seems fine.
      # In CommonWorkPresenter#cache_buster_id we use the thumbnail method since we don't have the representative solr doc.
      return Time.parse(solr_document['timestamp']).to_i.to_s if solr_document['timestamp'].present?
      ""
    end

    def sample_rate
      solr_document['sample_rate_ssim']
    end

    def duration
      duration = solr_document['duration_ssim']&.first
      # return if duration is blank or "contains no non-digit characters" is false, which implies a millisecond...
      # value, e.g. from MediaInfo
      return solr_document['duration_ssim'] if duration.blank? || (duration !~ /\D/) == false

      s, ms = duration.to_i.divmod(1000)
      m, s = s.divmod(60)
      h, m = m.divmod(60)

      # don't show the millisecond part if it's zero
      s = ms.zero? ? "#{h}:#{m}:#{s}" : "#{h}:#{m}:#{s}:#{ms}"
      # Array() as it's expected elsewhere to be a multivalued field (the 'm' in '_ssim')
      Array(s)
    end

    def original_name
      solr_document['original_name_tesim']
    end

    instrument_method
    def file_set
      @file_set ||= ::FileSet.find(id)
    end

    instrument_method
    def file
      # Get the original file from Fedora
      file = file_set&.original_file
      raise "FileSet #{id} original file is nil." if file.nil?
      file
    end

    instrument_method
    def extracted_text_file
      file_set&.extracted_text
    end

    instrument_method
    def extracted_text?
      # TODO: remove this line when we have some extracted text in place that's worth offering for download...
      # and/or a disclaimer as outlined in https://github.com/mlibrary/heliotrope/issues/1429
      return false if Rails.env.eql?('production')
      extracted_text_file&.size&.positive?
    end

    def thumbnail_path
      solr_document['thumbnail_path_ss']
    end

    def using_default_thumbnail?
      thumbnail_path.start_with?('/assets/')
    end

    def gylphicon
      tag.span class: glyphicon_type + " file-set-glyphicon", "aria-label": alt_text&.first || ""
    end

    def glyphicon_type
      return 'glyphicon glyphicon-file' if resource_type.blank?
      glyphicon_by_resource_type
    end

    def glyphicon_by_resource_type
      case resource_type.first.downcase
      when 'text'
        'glyphicon glyphicon-file'
      when 'image'
        'glyphicon glyphicon-picture'
      when 'video'
        'glyphicon glyphicon-film'
      when 'audio'
        'glyphicon glyphicon-volume-up'
      when 'map', 'interactive map'
        'glyphicon glyphicon-map-marker'
      else
        'glyphicon glyphicon-file'
      end
    end

    def use_riiif_for_icon?
      # sidestep hydra-derivatives and use riiif for FileSet icons
      eps?
    end

    def use_glyphicon?
      # If the thumbnail_path in Solr points to the assets directory, it is using a Hyrax default.
      # aside: Much of the thumbnail behavior can be examined by reading this page and its links to Hyrax code:
      # https://github.com/samvera/hyrax/wiki/How-Thumbnails-Get-rendered
      # Anyway, this default (set with a call to ActionController::Base.helpers.image_path) can't be styled per...
      # publisher so instead we'll use resource-type-specific glyphicons in "publisher branding" colors
      mime_type.blank? || external_resource? || using_default_thumbnail?
    end

    def use_svgicon?
      mime_type.blank? || external_resource? || content_warning.present? || using_default_thumbnail?
    end

    def svgicon_type
      case resource_type&.first&.downcase
      when 'text'
        'svgicon/text.svg'
      when 'image'
        'svgicon/image.svg'
      when 'video'
        'svgicon/video.svg'
      when 'audio'
        'svgicon/audio.svg'
      when 'map', 'interactive map'
        'svgicon/map.svg'
      else
        'svgicon/default.svg'
      end
    end

    def svgicon_alt
      case resource_type&.first&.downcase
      when 'text'
        'Document File Icon'
      when 'image'
        'Image File Icon'
      when 'video'
        'Video File Icon'
      when 'audio'
        'Audio File Icon'
      when 'map', 'interactive map'
        'Location Map Icon'
      else
        'Document File Icon'
      end
    end

    def center_caption?
      # when using the default thumbnail view (or glyphicon) both this and the download button are centered.
      # The caption lies between these. It looks very weird if it's left-aligned, especially if it's short.
      !image? && !video? && !audio? && !external_resource?
    end

    def download_button_label
      extension = File.extname(label).delete('.').upcase if label.present?
      download_label = extension == 'PDF' ? 'View' : 'Download'
      size = ActiveSupport::NumberHelper.number_to_human_size(file_size) if file_size.present?
      download_label += ' ' + extension if extension.present?
      download_label += ' (' + size + ')' if size.present?
      download_label
    end

    def extracted_text_download_button_label
      'Download TXT (' + ActiveSupport::NumberHelper.number_to_human_size(extracted_text_file.size) + ')'
    end

    def extracted_text_download_filename
      File.basename(label, '.*') + '.txt'
    end

    def heliotrope_media_partial(directory = 'media_display') # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # we've diverged from the media_display_partial stuff in Hyrax, so check our asset-page partials here
      partial = 'hyrax/file_sets/' + directory + '/'
      partial + if external_resource?
                  'external_resource'
                # this needs to come before `elsif image?` as these are also images
                # less than 430 or so px wide means a "responsive" iframe with a 5:3 ratio will not fit a Leaflet...
                # map with enough height for a single 256x256px tile. But actually it might make more sense to have...
                # < 540 here as that's the width of the Leaflet map on the FileSet show page
                elsif animated_gif? || (image? && width.present? && width < 450)
                  'static_image'
                elsif image?
                  'leaflet_image'
                elsif video?
                  'video'
                elsif audio?
                  'audio'
                elsif epub?
                  'epub'
                elsif eps?
                  'image_service'
                elsif interactive_map?
                  'interactive_map'
                elsif webgl?
                  'webgl'
                else
                  'default'
                end
    end

    # Hyrax 2.x update, needed for the monograph show page
    # Which we're probably getting rid of anyway, but... well whatever
    def user_can_perform_any_action?
      current_ability.can?(:edit, id) || current_ability.can?(:destroy, id) || current_ability.can?(:download, id)
    end

    # Returns true if the MIME type is image, or if MIME type is not available,
    # if the file extension is a known image type.
    def probable_image?
      return true if mime_type&.start_with?('image/')
      return false if label.nil?
      %w[.bmp .gif .jp2 .jpeg .jpg .png .tif .tiff].member?(File.extname(label).downcase)
    end

    def animated_gif?
      solr_document['animated_gif_bsi'] == true
    end

    private

      instrument_method
      def fetch_parent_presenter
        @parent_document ||= ActiveFedora::SolrService.query("{!field f=member_ids_ssim}#{id}", rows: 1).first
        return nil if @parent_document.blank?

        case @parent_document["has_model_ssim"].first
        when "Monograph"
          Hyrax::MonographPresenter.new(::SolrDocument.new(@parent_document), current_ability)
        else
          WorkShowPresenter.new(::SolrDocument.new(@parent_document), current_ability)
        end
      end
  end
end
