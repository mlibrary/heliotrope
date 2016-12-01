class DownloadsController < ApplicationController
  include CurationConcerns::DownloadBehavior

  def show
    if transcript?
      render text: file_set_doc['transcript_tesim'].first

    elsif thumbnail? || video? || sound? || allow_download?
      # See #401
      if file.is_a? String
        # For derivatives stored on the local file system
        response.headers['Accept-Ranges'] = 'bytes'
        response.headers['Content-Length'] = File.size(file).to_s
        file.sub!(/releases\/\d+/, "current")
        response.headers['X-Sendfile'] = file
        send_file file, derivative_download_options
      else
        super
      end
    else
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    end
  end

  def file_set_doc
    ActiveFedora::SolrService.query("{!terms f=id}#{params[:id]}").first || {}
  end

  def mime_type_for(file)
    # See #427
    mime_type = `file --brief --mime-type #{file.shellescape}` || MIME::Types.type_for(File.extname(file)).first.content_type
    mime_type.chomp
  end

  def allow_download?
    if file_set_doc['allow_download_ssim'].first == 'yes'
      true
    else
      false
    end
  end

  def thumbnail?
    if params[:file] == 'thumbnail'
      true
    else
      false
    end
  end

  def video?
    # video "previews"
    if params[:file] == 'webm' || params[:file] == 'mp4'
      true
    else
      false
    end
  end

  def sound?
    # sound "previews"
    if params[:file] == 'mp3' || params[:file] == 'ogg'
      true
    else
      false
    end
  end

  def transcript?
    if params[:file] == 'vtt'
      true
    else
      false
    end
  end
end
