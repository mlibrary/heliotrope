require 'rails_helper'

describe CurationConcerns::Renderers::MarkdownAttributeRenderer do
  let(:field) { :name }
  let(:renderer) { described_class.new(field, ['_Bob Italic_', '__Jessica Strong__']) }

  describe "#attribute_to_html" do
    subject { Nokogiri::HTML(renderer.render) }
    let(:expected) { Nokogiri::HTML(tr_content) }
    let(:tr_content) {
      "<tr><th>Name</th>\n" \
      "<td><ul class='tabular'><li class=\"attribute name\"><em>Bob</em></li>\n" \
      "<li class=\"attribute name\"><strong>Jessica</strong></li>\n" \
      "</ul></td></tr>"
    }
    # it { expect(subject).to be_equivalent_to(expected) }
    it { expect(subject).to match(expected) }
  end
end
