require 'rails_helper'

describe MarkdownService do
  let(:html) { "This is _italics_ and this is __bold__" }

  it "renders html from markdown" do
    expect(described_class.markdown(html)).to eq("This is <em>italics</em> and this is <strong>bold</strong>\n")
  end
end
