# frozen_string_literal: true

Hyrax::DownloadsController.class_eval do # rubocop:disable Metrics/BlockLength
  prepend(DownloadsControllerBehavior = Module.new do
    include IrusAnalytics::Controller::AnalyticsBehaviour

    # for animated GIF files we use the repo asset for display. They need to be "downloadable" no matter what.
    delegate :animated_gif?, to: :presenter

    def show # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      if closed_captions?
        render plain: presenter.closed_captions
      elsif visual_descriptions?
        render plain: presenter.visual_descriptions
      elsif embed_css?
        # try to prevent browsers caching these tiny CSS files, so that any changes will be picked up immediately
        response.set_header('Last-Modified', Time.now.httpdate)
        response.set_header('Expires', '0')
        response.set_header('Pragma', 'no-cache')
        response.set_header('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0, pre-check=0, post-check=0')
        # https://stackoverflow.com/a/55101169
        render body: presenter.embed_code_css, content_type: 'text/css'
      elsif file.present? && (thumbnail? || jpeg? || video? || sound? || animated_gif? || allow_download?)
        # See #401
        if file.is_a? String
          # For derivatives stored on the local file system
          response.headers['Accept-Ranges'] = 'bytes'
          response.headers['Content-Length'] = File.size(file).to_s
          updated_file_path = file.sub(/releases\/\d+/, "current")
          response.headers['X-Sendfile'] = updated_file_path
          send_file updated_file_path, derivative_download_options
        else
          if should_be_watermarked?
            redirect_to Rails.application.routes.url_helpers.download_ebook_url(presenter.id)
          else
            CounterService.from(self, presenter).count(request: 1)
            send_irus_analytics_request
            self.status = 200
            send_file_headers! content_options.merge(disposition: disposition(presenter))
            response.headers['Content-Length'] ||= file.size.to_s
            response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
            stream_body file.stream
          end
        end
      else
        render 'hyrax/base/unauthorized', status: :unauthorized
      end
    end

    # See HELIO-3966
    # Send the watermarked file for things that should be watermarked if the user is unprivileged
    def should_be_watermarked?
      presenter.pdf_ebook? && Press.where(subdomain: presenter.parent.subdomain)&.first.watermark && !can?(:edit, FileSet.find(params[:id]))
    end

    def item_identifier_for_irus_analytics
      CatalogController.blacklight_config.oai[:provider][:record_prefix] + ":" + presenter&.parent&.id
    end

    def disposition(presenter)
      return "inline" if presenter.pdf_ebook? == false && presenter.file_format&.match?(/^pdf/i)
      "attachment"
    end

    # going to tweak this function from Hyrax to return the thumbnail if the full-size screenshot is empty
    def load_file
      file_reference = params[:file]

      return default_file unless file_reference
      return extracted_text_file if file_reference == 'extracted_text'

      file_path = Hyrax::DerivativePath.derivative_path_for_reference(params[asset_param_key], file_reference)
      # pre-tweak this is the last line
      # File.exist?(file_path) ? file_path : nil

      if File.exist?(file_path)
        file_path
      elsif jpeg?
        # you wanted the full-size poster, but it doesn't exist... you get the thumbnail
        file_path = Hyrax::DerivativePath.derivative_path_for_reference(params[asset_param_key], 'thumbnail')
        File.exist?(file_path) ? file_path : nil
      end
    end

    def extracted_text_file
      # just copying default_file behavior with :extracted_text instead of default_content_path (a.k.a. :original_file)
      association = dereference_file(:extracted_text)
      association&.reader
    end

    def presenter
      Hyrax::PresenterFactory.build_for(ids: [params[:id]], presenter_class: Hyrax::FileSetPresenter, presenter_args: current_ability).first
    end

    def mime_type_for(file)
      # See #427
      mime_type = `file --brief --mime-type #{file.shellescape}` || MIME::Types.type_for(File.extname(file)).first.content_type
      mime_type.chomp
    end

    def allow_download?
      ResourceDownloadOperation.new(current_actor, Sighrax.from_noid(params[:id])).allowed?
    end

    # HELIO-4501 Override to use the Hyrax 3.4 version of this with no workflow related code.
    def authorize_download!
      return true if authorize_thumbs_and_embeds_for_share_link?

      authorize! :download, params[asset_param_key]
    rescue CanCan::AccessDenied
      unauthorized_image = Rails.root.join("app", "assets", "images", "unauthorized.png")
      send_file unauthorized_image, status: :unauthorized
    end

    def authorize_thumbs_and_embeds_for_share_link?
      # adding some logic to allow *draft* FileSet "downloads" to work when a session holds the sibling EPUB's share link.
      # This is specifically so that draft embedded video, jpeg (video poster), audio and animated gif resources will display in CSB.
      # Images will work anyway seeing as RIIIF tiles get served regardless of the originating FileSet's publication status.

      share_link = params[:share] || session[:share_link]
      session[:share_link] = share_link if share_link.present?

      # note we're *not* authorizing *all* FileSet downloads from Fedora here, just those tied to display
      if thumbnail? || jpeg? || video? || sound? || animated_gif? || closed_captions? || visual_descriptions?
        if share_link.present?
          begin
            decoded = JsonWebToken.decode(share_link)

            return true if decoded[:data] == presenter&.parent&.id
          rescue JWT::ExpiredSignature
            false
          end
        end
      else
        false
      end
    end

    def thumbnail?
      params[:file] == 'thumbnail'
    end

    def jpeg?
      # want this for HTML5 video tag poster attribute, it's a full-size screenshot of the video
      params[:file] == 'jpeg'
    end

    def video?
      # video "previews"
      params[:file] == 'mp4'
    end

    def sound?
      # sound "previews"
      params[:file] == 'mp3'
    end

    def closed_captions?
      params[:file] == 'captions_vtt'
    end

    def visual_descriptions?
      params[:file] == 'descriptions_vtt'
    end

    def embed_css?
      params[:file] == 'embed_css'
    end
  end)
end
