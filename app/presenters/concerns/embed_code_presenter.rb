# frozen_string_literal: true

module EmbedCodePresenter
  extend ActiveSupport::Concern

  def embeddable_type?
    image? || video? || audio? || interactive_application? || interactive_map? || youtube_player_video?
  end

  def allow_embed?
    current_ability&.platform_admin?
  end

  def embed_code
    if video? || image? || interactive_application? || interactive_map? || youtube_player_video?
      responsive_embed_code
    elsif audio?
      audio_embed_code
    end
  end

  # all the styles from the relevant embed code, which we can make available as a CSS stylesheet through DownloadsController
  def embed_code_css
    if video? || image? || interactive_application? || interactive_map?
      responsive_embed_code_css
    elsif audio?
      audio_embed_code_css
    end
  end

  def embed_link
    embed_url(hdl: HandleNet::FULCRUM_HANDLE_PREFIX + id)
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
    if root_url.exclude?('fulcrum')
      hyrax_file_set_url(id)
    else
      citable_link
    end
  end

  def responsive_embed_code
    <<~END
      <div style='width:#{outer_div_width}; page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; max-width:#{embed_max_width}px; margin:auto; background-color:#000'>
        <div style='overflow:hidden; padding-bottom:#{padding_bottom}%; position:relative; height:0;'>#{embed_height_string}
          <iframe loading='lazy' src='#{embed_link}' title='#{embed_code_title}' style='overflow:hidden; border-width:0; left:0; top:0; width:100%; height:100%; position:absolute;'#{frameborder}></iframe>
        </div>
      </div>
    END
  end

  # all the styles from `responsive_embed_code` which we can make available as a CSS stylesheet through DownloadsController
  def responsive_embed_code_css
    <<~END
      #fulcrum-embed-outer-#{id} {
        width:#{outer_div_width};
        page-break-inside:avoid;
        -webkit-column-break-inside:avoid;
        break-inside:avoid;
        max-width:#{embed_max_width}px;
        margin:auto;
        background-color:#000;
      }
      #fulcrum-embed-inner-#{id} {
        overflow:hidden;
        padding-bottom:#{padding_bottom}%;
        position:relative; height:0;
      }
      iframe#fulcrum-embed-iframe-#{id} {
        overflow:hidden;
        border-width:0;
        left:0; top:0;
        width:100%;
        height:100%;
        position:absolute;
      }
    END
  end

  def audio_embed_code
    # `height: 125px` allows for Able Player's controls. Both the controls and the audio-transcript-container div take up 375px of height, but the iframe should auto-adjust its height as required
    "<iframe loading='lazy' src='#{embed_link}' title='#{embed_code_title}' style='page-break-inside:avoid; -webkit-column-break-inside:avoid; break-inside:avoid; display:block; overflow:hidden; border-width:0; width:98%; max-width:98%; height:#{audio_embed_height}px; margin:auto'></iframe>"
  end

  # all the styles from `audio_embed_code` which we can make available as a CSS stylesheet through DownloadsController
  def audio_embed_code_css
    # note that we're allowing for the nested "responsive" divs here, enabling embed code consistency even though...
    # they serve no purpose for the audio player
    <<~END
      #fulcrum-embed-outer-#{id} {
      }
      #fulcrum-embed-inner-#{id} {
      }
      iframe#fulcrum-embed-iframe-#{id} {
        page-break-inside:avoid;
        -webkit-column-break-inside:avoid;
        break-inside:avoid;
        display:block;
        overflow:hidden;
        border-width:0;
        width:98%;
        max-width:98%;
        height:#{audio_embed_height}px;
        margin:auto;
      }
    END
  end

  # This value is used as the max-width of the responsive divs, preventing unnecessarily huge image and video embeds
  def embed_max_width
    if (video? || youtube_player_video?) && (width_ok? && height_ok?) && (height >= width)
      # Prevent portrait-mode videos from taking huge height by restricting width, this is especially relevant in...
      # scroll mode. Portrait images are not such an issue as we use a landscape-orientation Leaflet map for them.
      width / 2
    elsif width_ok?
      width
    else
      # 1000px is a fallback when characterization has failed to store a width value for the media, or when the...
      # embedded FileSet is an interactive map (zip) where `hydra-file_characterization` knows nothing about how to...
      # get the dimensions of the map inside.
      1000
    end
  end

  def embed_height
    height_ok? ? height : 'unknown'
  end

  def embed_height_string
    return '' if youtube_player_video?

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

  def padding_bottom  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    # images have pan/zoom and are often portrait, which would gobble up massive height, so we used to use 60% for all
    # but see HELIO-3242. Small portrait images get a negative zoom. Maps that are closer to square will cause...
    # fewer issues with "best fit" initial zoom. So for portrait or square images I'll bump the bottom padding to 80%.
    if video? || youtube_player_video?
      # adjusts the height to allow for what the video player is doing to preserve the content's aspect ratio
      percentage = !width_ok? || !height_ok? ? 75 : (height.to_f * 100.0 / width.to_f).round(2)

      # HELIO-3674: stick an extra 20% onto the height to make room for the `able-descriptions` div
      # This is not a good universal/long-term solution. There will be a limit to the amount of text that can...
      # be shown at one time before it is cut off by the allowed height of the iframe-wrapping divs.
      percentage = (percentage * 1.2).round(2) if visual_descriptions.present?

      (percentage % 1).zero? ? percentage.to_i : percentage
    else
      return 60 unless width.present? && height.present?
      width > height ? 60 : 80
    end
  end

  def outer_div_width
    # we'll restrict portrait-orientation videos to a width of 40% of the available _vertical_ height (40vh), which...
    # should leave some room for the figcaption etc beneath in most viewport sizes in page-by-page mode.
    # Note that in scroll mode, vertical height is basically infinite (The entire chapter), so we'll use a smaller...
    # max-width value on this div to restrain portrait videos in scroll mode.
    if (video? || youtube_player_video?) && (width_ok? && height_ok?) && (height >= width)
      '40vh'
    else
      'auto'
    end
  end

  # The Able Player "interactive transcript" div will only be present if our `closed_captions` field is set
  # this method is only used to allow height for the volume bar, it's used in the parent partial,...
  # app/views/hyrax/file_sets/_media_embedded.html.erb, which is not audio-specific
  def audio_without_closed_captions?
    audio? && closed_captions.blank?
  end

  def audio_embed_height
    closed_captions.present? ? 300 : 125
  end

  def frameborder
    youtube_player_video? ? ' frameborder="0"' : ''
  end
end
