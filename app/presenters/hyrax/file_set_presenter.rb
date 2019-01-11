# frozen_string_literal: true

module Hyrax
  class FileSetPresenter
    include TitlePresenter
    include AnalyticsPresenter
    include CitableLinkPresenter
    include OpenUrlPresenter
    include ModelProxy
    include PresentsAttributes
    include CharacterizationBehavior
    include WithEvents
    include FeaturedRepresentatives::FileSetPresenter
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::TagHelper

    attr_accessor :solr_document, :current_ability, :request, :monograph_presenter, :file_set

    # @param [SolrDocument] solr_document
    # @param [Ability] current_ability
    # @param [ActionDispatch::Request] request the http request context
    def initialize(solr_document, current_ability, request = nil)
      @solr_document = solr_document
      @current_ability = current_ability
      @request = request
    end

    # CurationConcern methods
    delegate :stringify_keys, :human_readable_type, :collection?, :image?, :video?,
             :audio?, :pdf?, :office_document?, :representative_id, :to_s, to: :solr_document

    # Methods used by blacklight helpers
    delegate :has?, :first, :fetch, to: :solr_document

    # Metadata Methods
    delegate :resource_type, :caption, :alt_text, :description, :copyright_holder,
             :content_type, :creator, :creator_full_name, :contributor, :date_created,
             :keywords, :publisher, :language, :date_uploaded,
             :rights_statement, :license, :embargo_release_date, :lease_expiration_date, :depositor, :tags,
             :title_or_label, :section_title,
             :allow_download, :allow_hi_res, :copyright_status, :rights_granted,
             :exclusive_to_platform, :permissions_expiration_date,
             :allow_display_after_expiration, :allow_download_after_expiration, :credit_line,
             :holding_contact, :external_resource_url, :primary_creator_role,
             :display_date, :sort_date, :transcript, :translation, :file_format,
             :label, :redirect_to, :has_model, :date_modified, :visibility,
             to: :solr_document

    def subdomain
      Array(solr_document['press_tesim']).first
    end

    def press
      Array(solr_document['press_name_ssim']).first
    end

    def press_url
      Press.find_by(subdomain: subdomain).press_url
    end

    def monograph_id
      Array(solr_document['monograph_id_ssim']).first
    end

    def parent
      monograph
    end

    def monograph
      @monograph_presenter ||= Hyrax::PresenterFactory.build_for(ids: [monograph_id], presenter_class: Hyrax::MonographPresenter, presenter_args: current_ability).first
    end

    def subjects
      monograph.subject
    end

    def previous_id?
      monograph.previous_file_sets_id? id
    end

    def previous_id
      monograph.previous_file_sets_id id
    end

    def next_id?
      monograph.next_file_sets_id? id
    end

    def next_id
      monograph.next_file_sets_id id
    end

    def link_name
      current_ability.can?(:read, id) ? Array(solr_document['label_tesim']).first : 'File'
    end

    def multimedia?
      # currently just need this for COUNTER reports
      audio? || video? || image?
    end

    def external_resource?
      external_resource_url.present?
    end

    def allow_download?
      return false if external_resource?
      # safe navigation (&.) as current_Ability is nil in some specs, should match allow_download? logic in downloads_controller
      allow_download&.casecmp('yes')&.zero? || current_ability&.platform_admin? || current_ability&.can?(:edit, id)
    end

    def allow_embed?
      current_ability.platform_admin?
    end

    def embed_code
      if video? || image?
        responsive_embed_code
      else
        generic_embed_code
      end
    end

    def embed_link
      embed_url(hdl: HandleService.path(id))
    end

    def embed_fulcrum_logo_title
      # a number of titles have double quotes in/around them, but we need the hover-over title itself to demarcate
      # the asset title. Given that italicization has already been lost in the TitlePresenter, I think removing all
      # double quotes and re-quoting the whole "Fulcrum title" is the best solution
      'View "' + page_title.delete('"') + '" on Fulcrum'
    end

    def embed_fulcrum_logo_alt
      page_title.delete('"')
    end

    def embed_fulcrum_logo_link
      if !root_url.include?('fulcrum')
        hyrax_file_set_url(id)
      else
        citable_link
      end
    end

    def responsive_embed_code
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:#{embed_width}px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:#{padding_bottom}%; position:relative; height:0;'>#{embed_height_string}
            <iframe src='#{embed_link}' title='#{page_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    end

    def generic_embed_code
      "<iframe src='#{embed_link}' title='#{page_title}' style='display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; max-height:400px; margin:auto'></iframe>"
    end

    # Google Analytics
    def pageviews_over_time_graph_data
      [{ "label": "Total Pageviews", "data": flot_pageviews_over_time(id).to_a.sort }]
    end

    # Embed Code Stuff

    def embed_width
      width_ok? ? width : 400
    end

    def embed_height
      height_ok? ? height : 300
    end

    def embed_height_string
      media_type = if video?
                     ' video'
                   elsif image?
                     ' image'
                   else
                     ''
                   end
      height_ok? ? "<!-- actual#{media_type} height: #{embed_height}px -->" : ''
    end

    def width_ok?
      width.present? && !width.zero?
    end

    def height_ok?
      height.present? && !height.zero?
    end

    def padding_bottom
      # images have pan/zoom and are often portrait, which would gobble up massive height, so use 60% for all
      return 60 unless video?
      # adjusts the height to allow for what the video player is doing to preserve the content's aspect ratio
      percentage = !width_ok? || !height_ok? ? 75 : (height.to_f * 100.0 / width.to_f).round(2)
      (percentage % 1).zero? ? percentage.to_i : percentage
    end

    # Technical Metadata
    def width
      solr_document['width_is']
    end

    def height
      solr_document['height_is']
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

    def image_cache_breaker
      # using the Solr doc's timestamp even though it'll change on any metadata update.
      # More file-specific fields on the Solr doc can't be trusted to be ordered in a useful way on "reversioning".
      # An alternative could be to pull the timestamp from the Hydra Derivatives thumbnail itself.
      value = ''
      if solr_document['timestamp'].present?
        # "2018-09-18T18:18:28.384Z" vs. "2018-09-18T18:18:28Z", see https://tools.lib.umich.edu/jira/browse/HELIO-2167
        format = solr_document['timestamp'].length > 20 ? '%Y-%m-%dT%H:%M:%S.%L%Z' : '%Y-%m-%dT%H:%M:%S%Z'
        value += '?' + Time.strptime(solr_document['timestamp'], format).to_i.to_s
      end
      value
    end

    def sample_rate
      solr_document['sample_rate_ssim']
    end

    def duration
      solr_document['duration_ssim']
    end

    def original_name
      solr_document['original_name_tesim']
    end

    def file_set
      @file_set ||= ::FileSet.find(id)
    end

    def file
      # Get the original file from Fedora
      file = file_set&.original_file
      raise "FileSet #{id} original file is nil." if file.nil?
      file
    end

    def extracted_text_file
      file_set&.extracted_text
    end

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
      return 'glyphicon glyphicon-file' if pdf? || resource_type.blank?
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
      else
        'glyphicon glyphicon-file'
      end
    end

    def use_glyphicon?
      # If the thumbnail_path in Solr points to the assets directory, it is using a Hyrax default.
      # aside: Much of the thumbnail behavior can be examined by reading this page and its links to Hyrax code:
      # https://github.com/samvera/hyrax/wiki/How-Thumbnails-Get-rendered
      # Anyway, this default (set with a call to ActionController::Base.helpers.image_path) can't be styled per...
      # publisher so instead we'll use resource-type-specific glyphicons in "publisher branding" colors
      mime_type.blank? || external_resource? || using_default_thumbnail?
    end

    def center_caption?
      # when using the default thumbnail view (or glyphicon) both this and the download button are centered.
      # The caption lies between these. It looks very weird if it's left-aligned, especially if it's short.
      !image? && !video? && !audio? && !external_resource?
    end

    def download_button_label
      download_label = 'Download'
      extension = File.extname(label).delete('.').upcase if label.present?
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

    def heliotrope_media_partial(directory = 'media_display')
      # we've diverged from the media_display_partial stuff in Hyrax, so check our asset-page partials here
      partial = 'hyrax/file_sets/' + directory + '/'
      partial + if external_resource?
                  'external_resource'
                elsif image?
                  'leaflet_image'
                elsif video?
                  'video'
                elsif audio?
                  'audio'
                elsif epub?
                  'epub'
                else
                  'default'
                end
    end
  end
end
