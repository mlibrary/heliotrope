class DownloadsController < ApplicationController
  include CurationConcerns::DownloadBehavior

  attr_accessor :file_mime_type

  def show
    if thumbnail? || video? || sound? || allow_download?
      # override some CC DownloadBehavior
      case file
      when String
        # For derivatives stored on the local file system
        helio_send_content
      else
        super
      end
    else
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    end
  end

  def mime_type_for(file)
    # See #427
    @file_mime_type ||= `file --brief --mime-type #{file.shellescape}`.chomp || MIME::Types.type_for(File.extname(file)).first.content_type
  end

  #
  # See #401
  # Some browsers (Safari, iOS) need the app/Apache to accept byte range requests
  # We can do this in Apache by setting the "X-Sendfile" header:
  #   response.headers['X-Sendfile'] = file if video?
  #   super
  # but we'd need to have mod_xsendfile installed in Apache
  # https://tn123.org/mod_xsendfile/ which may present some issues
  # (staging vs. preview, load balancer, etc) that we'll need to work through.
  #
  # hydra-head does it this way:
  # https://github.com/projecthydra/hydra-head/blob/master/hydra-core/app/controllers/concerns/hydra/controller/download_behavior.rb#L94
  # Because in the future we're going to be completely changing the way
  # we do video, see #398, maybe this is good enough for a temporary solution

  #
  # This is adapted from hydra-head, but instead of File object, we're using a string of the derivative path
  # These temporary methods are all prefixed with "helio_"
  #

  # Handle the HTTP show request
  def helio_send_content
    response.headers['Accept-Ranges'] = 'bytes'

    if request.head?
      helio_send_content_head
    elsif request.headers['HTTP_RANGE']
      helio_send_range
    else
      helio_send_file_contents
    end
  end

  # render an HTTP HEAD response
  def helio_content_head
    response.headers['Content-Length'] = File.size(file).to_s
    head :ok, content_type: mime_type_for(file)
  end

  # Create some headers for the datastream
  def helio_content_options
    { disposition: 'inline', type: mime_type_for(file), filename: File.basename(file) }
  end

  # render an HTTP Range response
  def helio_send_range
    _, range = request.headers['HTTP_RANGE'].split('bytes=')
    from, to = range.split('-').map(&:to_i)
    to = File.size(file).to_i - 1 unless to
    length = to - from + 1
    response.headers['Content-Range'] = "bytes #{from}-#{to}/#{File.size(file)}"
    response.headers['Content-Length'] = length.to_s
    self.status = 206
    helio_prepare_file_headers
    # stream_body file.stream(request.headers['HTTP_RANGE'])
    response.stream.write IO.binread(file, length, from)
  end

  def helio_send_file_contents
    self.status = 200
    helio_prepare_file_headers
    # stream_body file.stream
    helio_stream_body FileBody.new(file)
  end

  def helio_prepare_file_headers
    helio_content_options
    response.headers['Content-Type'] = mime_type_for(file)
    response.headers['Content-Length'] ||= File.size(file).to_s
    # Prevent Rack::ETag from calculating a digest over body
    # response.headers['Last-Modified'] = asset.modified_date.utc.strftime("%a, %d %b %Y %T GMT")
    response.headers['Last-Modified'] = File.mtime(file).utc.strftime("%a, %d %b %Y %T GMT")
    self.content_type = mime_type_for(file)
  end

  def helio_stream_body(iostream)
    iostream.each do |in_buff|
      response.stream.write in_buff
    end
  ensure
    response.stream.close
  end

  #
  # End hydra-head code
  #

  private

    def allow_download?
      @file_set ||= FileSet.find(params[:id])
      if @file_set.allow_download == 'yes'
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
end
