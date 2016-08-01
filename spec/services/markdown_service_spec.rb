require 'rails_helper'

describe MarkdownService do
  let(:html) { "This is _italics_ and this is __bold__ and this is ~~strikethrough~~" }

  it "renders html from markdown" do
    expect(described_class.markdown(html)).to eq("This is <em>italics</em> and this is <strong>bold</strong> and this is <del>strikethrough</del>\n")
  end
end
