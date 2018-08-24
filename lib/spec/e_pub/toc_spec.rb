# frozen_string_literal: true

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
              <li><a href="chapter2.xhtml">Chapter 2</a><li>
              <ol>
                <li><a href="10_Chapter02.1.xhtml">Section 2 1</a><li>
                <ol>
                  <li><a href="11_Chapter02.1.1.xhtml">Segment 2 1 1</a><li>
                  <li><a href="../Text/c02.1.2.xhtml">Segment 2 1 2</a><li>
                  <li><a href="chapter2.1.3.xhtml">Segment 2 1 3</a><li>
                </ol>
                <li><a href="../Text/c02.2.xhtml">Section 2 2</a><li>
                <ol>
                  <li><a href="12_Chapter02.2.1.xhtml">Segment 2 2 1</a><li>
                  <li><a href="../Text/c02.2.2.xhtml">Segment 2 2 2</a><li>
                  <li><a href="chapter2.2.3.xhtml">Segment 2 2 3</a><li>
                </ol>
                <li><a href="chapter2.3.xhtml">Section 2 3</a><li>
                <ol>
                  <li><a href="14_Chapter02.3.1.xhtml">Segment 2 3 1</a><li>
                  <li><a href="../Text/c02.3.2.xhtml">Segment 2 3 2</a><li>
                  <li><a href="chapter2.2.3.xhtml">Segment 2 2 3</a><li>
                </ol>
              </ol>
            </ol>
          </nav>
        </body>
      </html>
    ')
  end

  describe "#chapter_title" do
    context "flat TOC" do
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
          allow(EPub.logger).to receive(:info).and_return(nil)
          expect(subject.chapter_title(none.children[0])).to eq ''
        end
      end
    end

    context "Hierarchical TOC" do
      context "with a simple match" do
        # NYPress Paratext book
        let(:simple) { Nokogiri::XML('<item id="Chapter02.1" href="10_Chapter02.1.xhtml" media-type="application/xhtml+xml"/>') }

        it { expect(subject.chapter_title(simple.children[0])).to eq 'Section 2 1' }
      end

      context "with a one higher directory match (../)" do
        # One of the HEB books (heb99048.0001.001)
        let(:oneup) { Nokogiri::XML('<item id="c02.2" href="Text/c02.2.xhtml" media-type="application/xhtml+xml"/>') }

        it { expect(subject.chapter_title(oneup.children[0])).to eq 'Section 2 2' }
      end

      context "with a 'base' match" do
        # I'm not sure which epub this is for but at one point we needed to do
        # File.basename(chapter_href) to get chapter titles to work for... something
        # A multiple-rendition thing? Not sure.
        let(:base) { Nokogiri::XML('<item id="2.1.3" href="WHATWHY/chapter2.1.3.xhtml">') }

        it { expect(subject.chapter_title(base.children[0])).to eq 'Segment 2 1 3' }
      end

      context "no match" do
        let(:none) { Nokogiri::XML('<item id="x" href="notevenclose.xhtml"> ') }

        it do
          allow(EPub.logger).to receive(:info).and_return(nil)
          expect(subject.chapter_title(none.children[0])).to eq ''
        end
      end
    end
  end
end
