# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Page do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::PageNullObject) }
    it { expect(subject.image).to be_empty }
  end

  describe '#from_chapter_anchor_element' do
    subject { described_class.from_chapter_span_parent_anchor_element(chapter, anchor_element) }

    let(:chapter) { double('chapter', full_path: 'full_path/chapter.xhtml') }
    let(:anchor_element) { double('anchor node') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::PageNullObject) }

    context 'Chapter' do
      before { allow(chapter).to receive(:instance_of?).with(EPub::Unmarshaller::Chapter).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::PageNullObject) }

      context 'Element' do
        let(:anchor_element) { Nokogiri::XML::Element.new('a', Nokogiri::XML::Document.parse(nil)) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.image).to be_empty }

        context 'Anchor' do
          let(:anchor_element) { span_element.parent.xpath(".//a").first }
          let(:span_element) { chapter_list_doc.xpath(".//span").first }
          let(:chapter_list_doc) { Nokogiri::XML::Document.parse(chapter_list_xml).remove_namespaces! }
          let(:chapter_list_xml) do
            <<-XML
              <?xml version="1.0" encoding="UTF-8"?>
              <html xmlns="http://www.w3.org/1999/xhtml">
                <head>
                  <meta name="viewport" content="width=device-width,height=device-height"/>
                </head>
                <body>
                  <nav xmlns:epub="http://www.idpf.org/2007/ops"
                    id="chapter-list"
                    epub:type="chapter-list"
                    hidden="">
                    <h1>List of Chapters</h1>
                    <ol>
                      <li class="frontmatter">
                        <span>Frontmatter</span>
                        <ol>
                          <li>
                            <a href="xhtml/00000001_fixed_ocr.xhtml"/>
                          </li>
                          <li>
                            <a href="xhtml/00000002_fixed_ocr.xhtml"/>
                          </li>
                        </ol>
                      </li>
                      <li class="part">
                        <span>PART ONE: THE POLIT ON THE MOVE</span>
                        <ol>
                          <li>
                            <a href="xhtml/00000047_fixed_ocr.xhtml"/>
                          </li>
                          <li>
                            <a href="xhtml/00000048_fixed_ocr.xhtml"/>
                          </li>
                        </ol>
                      </li>
                      <li class="chapter">
                        <span>Chapter 1. Sharks and Marks: The Swindles and Seductions of Modernity (page 33)</span>
                        <ol>
                          <li>
                            <a href="xhtml/00000049_fixed_ocr.xhtml"/>
                          </li>
                          <li>
                            <a href="xhtml/00000050_fixed_ocr.xhtml"/>
                          </li>
                        </ol>
                      </li>
                    </ol>
                  </nav>
                </body>
              </html>
            XML
          end
          let(:page_xml) do
            <<-XML
            <?xml version="1.0" encoding="UTF-8"?>
            <html xmlns="http://www.w3.org/1999/xhtml">
              <head>
                <meta name="viewport" content="width=2400,height=3600"/>
                <link href="../css/default.css" rel="stylesheet" type="text/css"/>
              </head>
              <body>
                <figure id="figure1">
                  <img src="../images/00000007.png" alt="heb"/>
                </figure>
              </body>
            </html>
            XML
          end

          before { allow(File).to receive(:open).with(File.join(File.dirname(chapter.full_path), "xhtml/00000001_fixed_ocr.xhtml")).and_return(page_xml) }

          it { is_expected.to be_an_instance_of(described_class) }
          it { expect(subject.image).to eq "full_path/xhtml/../images/00000007.png" }
        end
      end
    end
  end
end
