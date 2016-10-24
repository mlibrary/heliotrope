require 'rails_helper'

describe MarkdownService do
  describe '.markdown' do
    let(:html) { "\n\nThis is _italics_ and this is\n\na paragraph\n\n__bold__ a line\nbreak and this is ~~strikethrough~~" }
    let(:rvalue) { described_class.markdown(html) }

    it "renders html from markdown" do
      expect(rvalue).to eq("This is <em>italics</em> and this is</p>\n\n<p>a paragraph</p>\n\n<p><strong>bold</strong> a line<br>\nbreak and this is <del>strikethrough</del>")
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
