# frozen_string_literal: true

module SocialShareWidgetPresenter
  extend ActiveSupport::Concern

  def social_share_widget_template_content
    <<~END
      <div class="dropdown">
        <button class="button--sm dropdown-toggle" type="button" id="shareMenuButton" data-toggle="dropdown" aria-label="Promote on social media and share this book" aria-haspopup="true" aria-expanded="false">
          <i id="share" class="icon-share-boxed oi" data-glyph="share-boxed" title="Promote on social media and share this book" aria-hidden="true"></i>
        </button>
        <div class="dropdown-menu" aria-labelledby="shareMenuButton">
          #{social_share_link(:twitter)}
          #{social_share_link(:facebook)}
          #{social_share_link(:reddit)}
          #{social_share_link(:mendeley)}
        </div>
      </div>
    END
  end

  def social_share_widget_template
    social_share_widget_template_content.gsub(/(?:\n\r?|\r\n?)/, '').html_safe # rubocop:disable Rails/OutputSafety
  end

  def social_share_link(platform = nil)
    case platform
    when :twitter
      "<a class=\"dropdown-item\" href=\"http://twitter.com/intent/tweet?text=#{url_title}&url=#{citable_link}\" target=\"_blank\">Twitter</a>"
    when :facebook
      "<a class=\"dropdown-item\" href=\"http://www.facebook.com/sharer.php?u=#{citable_link}&t=#{url_title}\" target=\"_blank\">Facebook</a>"
    when :reddit
      "<a class=\"dropdown-item\" href=\"http://www.reddit.com/submit?url=#{citable_link}\" target=\"_blank\">Reddit</a>"
    when :mendeley
      "<a class=\"dropdown-item\" href=\"http://www.mendeley.com/import/?url=#{citable_link}\" target=\"_blank\">Mendeley</a>"
    end
  end
end
