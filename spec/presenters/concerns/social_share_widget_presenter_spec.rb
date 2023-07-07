# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SocialShareWidgetPresenter do
  let(:mono_doc) {
    SolrDocument.new(id: '999999999',
                     title_tesim: ['#hashtag Test monograph with _MD Italics_ and <em>HTML Italics</em>'])
  }

  let(:presenter) { Hyrax::MonographPresenter.new(mono_doc, nil) }

  let(:expected_widget_template_content) {
    <<~END
      <div class="dropdown">
        <button class="button--sm dropdown-toggle" type="button" id="shareMenuButton" data-toggle="dropdown" aria-label="Promote on social media and share this book" aria-haspopup="true" aria-expanded="false">
          <i id="share" class="icon-share-boxed oi" data-glyph="share-boxed" title="Promote on social media and share this book" aria-hidden="true"></i>
        </button>
        <div class="dropdown-menu" aria-labelledby="shareMenuButton">
          #{presenter.social_share_link(:twitter)}
          #{presenter.social_share_link(:facebook)}
          #{presenter.social_share_link(:reddit)}
          #{presenter.social_share_link(:mendeley)}
        </div>
      </div>
    END
  }

  describe "#social_share_widget_template" do
    it "has the correct HTML for the EPUB reader" do
      expect(presenter.social_share_widget_template).to eq(expected_widget_template_content.gsub(/(?:\n\r?|\r\n?)/, ''))
    end
  end

  describe "#social_share_link" do
    it "provides the correct link for each platform" do
      expect(presenter.social_share_link(:twitter)).to eq("<a class=\"dropdown-item\" href=\"http://twitter.com/intent/tweet?text=%23hashtag+Test+monograph+with+MD+Italics+and+HTML+Italics&url=https://hdl.handle.net/2027/fulcrum.999999999\" target=\"_blank\">Twitter</a>")
      expect(presenter.social_share_link(:facebook)).to eq("<a class=\"dropdown-item\" href=\"http://www.facebook.com/sharer.php?u=https://hdl.handle.net/2027/fulcrum.999999999&t=%23hashtag+Test+monograph+with+MD+Italics+and+HTML+Italics\" target=\"_blank\">Facebook</a>")
      expect(presenter.social_share_link(:reddit)).to eq("<a class=\"dropdown-item\" href=\"http://www.reddit.com/submit?url=https://hdl.handle.net/2027/fulcrum.999999999\" target=\"_blank\">Reddit</a>")
      expect(presenter.social_share_link(:mendeley)).to eq("<a class=\"dropdown-item\" href=\"http://www.mendeley.com/import/?url=https://hdl.handle.net/2027/fulcrum.999999999\" target=\"_blank\">Mendeley</a>")
    end
  end
end
