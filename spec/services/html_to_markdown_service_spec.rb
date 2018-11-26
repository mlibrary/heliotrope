# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HtmlToMarkdownService do
  describe '.markdown' do
    let(:html) { "This is <em>italics</em> and this is <p>a paragraph</p><strong>bold</strong> a line<br>\nbreak and this is <del>strikethrough</del>" }
    let(:rvalue) { described_class.convert(html) }

    it "produces markdown from html" do
      expect(rvalue).to eq("This is _italics_ and this is\n\na paragraph\n\n**bold** a line  \nbreak and this is ~~strikethrough~~")
    end

    it 'converts links in the (inline) manner to which we have become accustomed' do
      expect(described_class.convert('Come read a book on <a href="http://www.fulcrum.org">www.fulcrum.org</a> right now!'))
        .to eq('Come read a book on [www.fulcrum.org](http://www.fulcrum.org) right now!')
    end
  end
end
