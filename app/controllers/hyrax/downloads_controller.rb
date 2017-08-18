# frozen_string_literal: true

module Hyrax
  class DownloadsController < ApplicationController
    include Hyrax::DownloadBehavior

    def show
      if transcript?
        render plain: file_set_doc['transcript_tesim'].first
      elsif file.present? && (thumbnail? || jpeg? || video? || sound? || allow_download?)
        # See #401
        if file.is_a? String
          # For derivatives stored on the local file system
          response.headers['Accept-Ranges'] = 'bytes'
          response.headers['Content-Length'] = File.size(file).to_s
          file.sub!(/releases\/\d+/, "current")
          response.headers['X-Sendfile'] = file
          send_file file, derivative_download_options
        else
          self.status = 200
          send_file_headers! content_options.merge(disposition: 'attachment')
          response.headers['Content-Length'] ||= file.size.to_s
          response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
          stream_body file.stream
        end
      else
        render 'hyrax/base/unauthorized', status: :unauthorized
      end
    end

    # going to tweak this function from Hyrax to return the thumbnail if the full-size screenshot is empty
    def load_file
      file_reference = params[:file]
      return default_file unless file_reference

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

    def file_set_doc
      ActiveFedora::SolrService.query("{!terms f=id}#{params[:id]}", rows: 1).first || {}
    end

    def mime_type_for(file)
      # See #427
      mime_type = `file --brief --mime-type #{file.shellescape}` || MIME::Types.type_for(File.extname(file)).first.content_type
      mime_type.chomp
    end

    def allow_download?
      file_set_doc['allow_download_ssim'].first == 'yes' ? true : false
    end

    def thumbnail?
      params[:file] == 'thumbnail' ? true : false
    end

    def jpeg?
      # want this for HTML5 video tag poster attribute, it's a full-size screenshot of the video
      params[:file] == 'jpeg' ? true : false
    end

    def video?
      # video "previews"
      params[:file] == 'webm' || params[:file] == 'mp4' ? true : false
    end

    def sound?
      # sound "previews"
      params[:file] == 'mp3' || params[:file] == 'ogg' ? true : false
    end

    def transcript?
      params[:file] == 'vtt' ? true : false
    end
  end
end
