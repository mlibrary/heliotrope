# frozen_string_literal: true

require 'rails_helper'

describe MarkdownService do
  describe '.markdown' do
    let(:html) { "\n\nThis is _italics_ and this is\n\na paragraph\n\n__bold__ a line\nbreak and this is ~~strikethrough~~" }
    let(:rvalue) { described_class.markdown(html) }

    it "renders html from markdown" do
      expect(rvalue).to eq("This is <em>italics</em> and this is</p>\n\n<p>a paragraph</p>\n\n<p><strong>bold</strong> a line<br>\nbreak and this is <del>strikethrough</del>")
    end

    it 'autolinks internal autolinks in same tab' do
      expect(described_class.markdown('www.fulcrum.org')).to eq('<a href="http://www.fulcrum.org">www.fulcrum.org</a>')
    end

    it 'autolinks internal "named" links in same tab' do
      expect(described_class.markdown('[internal link name](www.fulcrumscholar.org)')).to eq('<a href="www.fulcrumscholar.org">internal link name</a>')
    end

    it 'autolinks internal "app path" links in same tab' do
      expect(described_class.markdown('[Northwestern](/northwestern)')).to eq('<a href="/northwestern">Northwestern</a>')
    end

    it 'autolinks external autolinks in new tab' do
      expect(described_class.markdown('www.example.com')).to eq('<a target="_blank" href="http://www.example.com">www.example.com</a>')
    end

    it 'autolinks external "named" links in new tab' do
      expect(described_class.markdown('[external link name](www.example.com)')).to eq('<a target="_blank" href="www.example.com">external link name</a>')
    end

    it 'returns safe html' do
      expect(rvalue).to be_a ActiveSupport::SafeBuffer
    end
  end

  describe '.markdown_as_text' do
    it 'renders italics' do
      expect(described_class.markdown_as_text('_italics_')).to eq('italics')
    end

    it 'renders bold' do
      expect(described_class.markdown_as_text('__bold__')).to eq('bold')
    end

    it 'renders strike-through' do
      expect(described_class.markdown_as_text('~~strike-through~~')).to eq('strike-through')
    end

    it 'renders line breaks' do
      expect(described_class.markdown_as_text("a line\nbreak")).to eq('a line break')
    end

    it 'renders paragraphs' do
      expect(described_class.markdown_as_text("\n\n\n\n\nfirst paragraph\nsecond paragraph\n\nthird paragraph\n\n\n\n\n")).to eq('first paragraph second paragraph third paragraph')
    end
  end
end
