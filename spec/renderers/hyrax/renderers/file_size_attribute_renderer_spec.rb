# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::Renderers::FileSizeAttributeRenderer do
  let(:field) { :file_size }

  describe "#attribute_to_html" do
    subject { renderer.render }
    let(:renderer) { described_class.new(field, '29414808', label: I18n.t('file_size')) }
    let(:expected) { tr_content }
    let(:tr_content) {
      "<tr><th>File Size</th>\n" \
      "<td><ul class='tabular list-unstyled'><li class=\"attribute file_size\">28.1 MB</li></ul></td></tr>"
    }
    it { expect(subject).to match(expected) }
  end
end
