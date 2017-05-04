# frozen_string_literal: true

require 'rails_helper'

describe CurationConcerns::Renderers::MarkdownAttributeRenderer do
  let(:field) { :name }

  describe "#attribute_to_html" do
    subject { renderer.render }
    let(:renderer) { described_class.new(field, ['_Bob Italic_', '__Jessica Strong__']) }
    let(:expected) { tr_content }
    let(:tr_content) {
      "<tr><th>Name</th>\n" \
      "<td><ul class='tabular list-unstyled'><li class=\"attribute name\"><em>Bob Italic</em></li>" \
      "<li class=\"attribute name\"><strong>Jessica Strong</strong></li>" \
      "</ul></td></tr>"
    }
    it { expect(subject).to match(expected) }
  end
end
