# frozen_string_literal: true

module Hyrax
  class FileSetPresenter
    include TitlePresenter
    include CCAnalyticsPresenter
    include OpenUrlPresenter
    include ModelProxy
    include PresentsAttributes
    include CharacterizationBehavior
    include WithEvents
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper

    attr_accessor :solr_document, :current_ability, :request, :monograph_presenter

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
             :title_or_label, :external_resource, :book_needs_handles, :section_title,
             :allow_download, :allow_hi_res, :copyright_status, :rights_granted,
             :rights_granted_creative_commons, :exclusive_to_platform, :permissions_expiration_date,
             :allow_display_after_expiration, :allow_download_after_expiration, :credit_line,
             :holding_contact, :ext_url_doi_or_handle, :doi, :hdl, :use_crossref_xml, :primary_creator_role,
             :display_date, :sort_date, :transcript, :translation, :file_format,
             :creator_given_name, :creator_family_name, :label, :redirect_to,
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

    def citable_link
      if doi.present?
        doi_url
      else
        handle_url
      end
    end

    def handle_url
      HandleService.url(self)
    end

    def doi_url
      doi
    end

    def external_resource?
      external_resource == 'yes'
    end

    def allow_download?
      return false if external_resource?
      # safe navigation (&.) as current_Ability is nil in some specs, should match allow_download? logic in downloads_controller
      allow_download == 'yes' || current_ability&.platform_admin? || current_ability&.can?(:edit, id)
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
      embed_url(hdl: HandleService.handle(self))
    end

    def embed_fulcrum_logo_title
      # a number of titles have double quotes in/around them, but we need the hover-over title itself to demarcate
      # the asset title. Given that italicization has already been lost in the TitlePresenter, I think removing all
      # double quotes and re-quoting the whole "Fulcrum title" is the best solution
      'View "' + page_title.delete('"') + '" on Fulcrum'
    end

    def embed_fulcrum_logo_link(protocol, host_with_port)
      return citable_link if id.blank?
      if (Rails.env.production? && host_with_port.include?('heliotrope')) || Rails.env.development?
        protocol + host_with_port + '/concern/file_sets/' + id
      else
        # actual production and test
        citable_link
      end
    end

    def responsive_embed_code
      <<~END
        <div style='width:auto; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:#{embed_width}px; margin:auto'>
          <div style='overflow:hidden; padding-bottom:#{padding_bottom}%; position:relative; height:0;'>#{embed_height_string}
            <iframe src='#{embed_link}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
          </div>
        </div>
      END
    end

    def generic_embed_code
      "<iframe src='#{embed_link}' style='display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; max-height:400px; margin:auto'></iframe>"
    end

    # Google Analytics
    def pageviews
      pageviews_by_path(hyrax_file_set_path(id))
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

    def sample_rate
      solr_document['sample_rate_ssim']
    end

    def duration
      solr_document['duration_ssim']
    end

    def original_name
      solr_document['original_name_tesim']
    end

    def epub?
      ['application/epub+zip'].include? mime_type
    end

    def manifest?
      ['text/csv', 'text/comma-separated-values'].include? mime_type
    end

    def file
      # Get the original file from Fedora
      file = ::FileSet.find(id)&.original_file
      raise "FileSet #{id} original file is nil." if file.nil?
      file
    end

    def thumbnail_path
      solr_document['thumbnail_path_ss']
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
      mime_type.blank? || external_resource == 'yes' || thumbnail_path.start_with?('/assets/')
    end

    def center_caption?
      # when using the default thumbnail view (or glyphicon) both this and the download button are centered.
      # The caption lies between these. It looks very weird if it's left-aligned, especially if it's short.
      !image? && !video? && !audio?
    end

    def download_button_label
      download_label = 'Download'
      extension = File.extname(label).delete('.').upcase if label.present?
      size = number_to_human_size(file_size) if file_size.present?
      download_label += ' ' + extension if extension.present?
      download_label += ' (' + size + ')' if size.present?
      download_label
    end
  end
end
