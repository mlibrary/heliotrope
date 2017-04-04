require 'rails_helper'

describe CurationConcerns::Renderers::MultilineAttributeRenderer do
  let(:field) { :transcript }

  describe "newlines only" do
    subject { renderer.render }
    let(:renderer) { described_class.new(field, ["_Bob_\n11:07 --> 11.61\n" \
                                               ">> [LAUGH]\n>> Stuff"]) }
    let(:expected) { tr_content }
    let(:tr_content) {
      "<tr><th>Transcript</th>\n" \
      "<td><ul class='tabular list-unstyled'><li class=\"attribute transcript\">_Bob_<br>" \
      "11:07 --&gt; 11.61<br>&gt;&gt; [LAUGH]<br>&gt;&gt; Stuff</li>" \
      "</ul></td></tr>"
    }
    it { expect(subject).to match(expected) }
  end
end
