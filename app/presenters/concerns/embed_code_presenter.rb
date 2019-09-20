# frozen_string_literal: true

module EmbedCodePresenter
  extend ActiveSupport::Concern

  def embeddable_type?
    image? || video? || audio? || map?
  end

  def allow_embed?
    current_ability.platform_admin?
  end

  def embed_code
    if video? || image? || map?
      responsive_embed_code
    elsif audio?
      audio_embed_code
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
    embed_code_title
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
          <iframe src='#{embed_link}' title='#{embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'></iframe>
        </div>
      </div>
    END
  end

  def audio_embed_code
    # `height: 125px` allows for Able Player's controls. Both the controls and the audio-transcript-container div take up 375px of height, but the iframe should auto-adjust its height as required
    "<iframe src='#{embed_link}' title='#{embed_code_title}' style='page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; height:125px; margin:auto'></iframe>"
  end

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

  def audio_without_transcript?
    audio? && transcript.blank?
  end
end
