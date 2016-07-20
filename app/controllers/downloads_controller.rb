class DownloadsController < ApplicationController
  include CurationConcerns::DownloadBehavior

  def show
    if thumbnail? || webm? || sound? || allow_download?
      super
    else
      render 'curation_concerns/base/unauthorized', status: :unauthorized
    end
  end

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

  def webm?
    # video "previews"
    if params[:file] == 'webm'
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
