require 'rails_helper'

describe MarkdownService do
  let(:html) { "\n\nThis is _italics_ and this is\n\na paragraph\n\n__bold__ and this is ~~strikethrough~~" }

  it "renders html from markdown" do
    expect(described_class.markdown(html)).to eq("This is <em>italics</em> and this is</p>\n\n<p>a paragraph</p>\n\n<p><strong>bold</strong> and this is <del>strikethrough</del>")
  end
end
