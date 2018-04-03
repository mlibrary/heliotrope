# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Toc do
  subject { described_class.new(toc_doc.remove_namespaces!) }
  let(:toc_doc) do
    Nokogiri::XML('
      <html>
        <body>
          <nav type="toc" id="toc">
            <ol>
              <li><a href="09_Chapter01.xhtml">1 From Spoilers to Spinoffs: A Theory of Paratexts</a></li>
              <li><a href="../Text/c04.xhtml">4. The World and the Chläus</a></li>
              <li><a href="chapter1.xhtml">Something...</a></li>
            </ol>
          </nav>
        </body>
      </html>
    ')
  end

  describe "#chapter_title" do
    context "with a simple match" do
      # NYPress Paratext book
      let(:simple) { Nokogiri::XML('<item id="Chapter01" href="09_Chapter01.xhtml" media-type="application/xhtml+xml"/>') }
      it { expect(subject.chapter_title(simple.children[0])).to eq '1 From Spoilers to Spinoffs: A Theory of Paratexts' }
    end

    context "with a one higher directory match (../)" do
      # One of the HEB books (heb99048.0001.001)
      let(:oneup) { Nokogiri::XML('<item id="c04" href="Text/c04.xhtml" media-type="application/xhtml+xml"/>') }
      it { expect(subject.chapter_title(oneup.children[0])).to eq '4. The World and the Chläus' }
    end

    context "with a 'base' match" do
      # I'm not sure which epub this is for but at one point we needed to do
      # File.basename(chapter_href) to get chapter titles to work for... something
      # A multiple-rendition thing? Not sure.
      let(:base) { Nokogiri::XML('<item id="1" href="WHATWHY/chapter1.xhtml">') }
      it { expect(subject.chapter_title(base.children[0])).to eq 'Something...' }
    end

    context "no match" do
      let(:none) { Nokogiri::XML('<item id="x" href="notevenclose.xhtml"> ') }
      it do
        allow(EPub.logger).to receive(:error).and_return(nil)
        expect(subject.chapter_title(none.children[0])).to eq ''
      end
    end
  end
end
