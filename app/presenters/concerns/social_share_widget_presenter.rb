# frozen_string_literal: true

module SocialShareWidgetPresenter
  extend ActiveSupport::Concern

  def social_share_widget_template_content
    <<~END
      <div class="btn-group">
        <button class="button--sm dropdown-toggle" data-toggle="dropdown" aria-label="Promote on social media and share this book" aria-haspopup="true" aria-expanded="false">
          <i id="share" class="icon-share-boxed oi" data-glyph="share-boxed" title="Promote on social media and share this book" aria-hidden="true"></i>
        </button>
        <ul class="dropdown-menu">
          <li>#{social_share_link(:twitter)}</li>
          <li>#{social_share_link(:facebook)}</li>
          <li>#{social_share_link(:google)}</li>
          <li>#{social_share_link(:reddit)}</li>
          <li>#{social_share_link(:mendeley)}</li>
          <li>#{social_share_link(:citeulike)}</li>
        </ul>
      </div>
    END
  end

  def social_share_widget_template
    social_share_widget_template_content.gsub(/(?:\n\r?|\r\n?)/, '').html_safe # rubocop:disable Rails/OutputSafety
  end

  def social_share_link(platform = nil) # rubocop:disable Metrics/CyclomaticComplexity
    case platform
    when :twitter
      "<a href=\"http://twitter.com/intent/tweet?text=#{url_title}&url=#{citable_link}\" target=\"_blank\">Twitter</a>"
    when :facebook
      "<a href=\"http://www.facebook.com/sharer.php?u=#{citable_link}&t=#{url_title}\" target=\"_blank\">Facebook</a>"
    when :google
      "<a href=\"https://plus.google.com/share?url=#{citable_link}\" target=\"_blank\">Google+</a>"
    when :reddit
      "<a href=\"http://www.reddit.com/submit?url=#{citable_link}\" target=\"_blank\">Reddit</a>"
    when :mendeley
      "<a href=\"http://www.mendeley.com/import/?url=#{citable_link}\" target=\"_blank\">Mendeley</a>"
    when :citeulike
      "<a href=\"http://www.citeulike.org/posturl?url=#{citable_link}&title=#{url_title}\" target=\"_blank\">Cite U Like</a>"
    end
  end
end
