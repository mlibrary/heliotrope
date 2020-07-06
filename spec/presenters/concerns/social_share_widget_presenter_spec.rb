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
      <div class="btn-group">
        <button class="button--sm dropdown-toggle" data-toggle="dropdown" aria-label="Promote on social media and share this book" aria-haspopup="true" aria-expanded="false">
          <i id="share" class="icon-share-boxed oi" data-glyph="share-boxed" title="Promote on social media and share this book" aria-hidden="true"></i>
        </button>
        <ul class="dropdown-menu">
          <li>#{presenter.social_share_link(:twitter)}</li>
          <li>#{presenter.social_share_link(:facebook)}</li>
          <li>#{presenter.social_share_link(:reddit)}</li>
          <li>#{presenter.social_share_link(:mendeley)}</li>
        </ul>
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
      expect(presenter.social_share_link(:twitter)).to eq("<a href=\"http://twitter.com/intent/tweet?text=%23hashtag+Test+monograph+with+MD+Italics+and+HTML+Italics&url=https://hdl.handle.net/2027/fulcrum.999999999\" target=\"_blank\">Twitter</a>")
      expect(presenter.social_share_link(:facebook)).to eq("<a href=\"http://www.facebook.com/sharer.php?u=https://hdl.handle.net/2027/fulcrum.999999999&t=%23hashtag+Test+monograph+with+MD+Italics+and+HTML+Italics\" target=\"_blank\">Facebook</a>")
      expect(presenter.social_share_link(:reddit)).to eq("<a href=\"http://www.reddit.com/submit?url=https://hdl.handle.net/2027/fulcrum.999999999\" target=\"_blank\">Reddit</a>")
      expect(presenter.social_share_link(:mendeley)).to eq("<a href=\"http://www.mendeley.com/import/?url=https://hdl.handle.net/2027/fulcrum.999999999\" target=\"_blank\">Mendeley</a>")
    end
  end
end
