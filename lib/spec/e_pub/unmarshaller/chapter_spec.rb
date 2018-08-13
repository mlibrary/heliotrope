# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Chapter do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterNullObject) }
    it { expect(subject.title).to be_empty }
    it { expect(subject.pages).to be_empty }
  end

  describe '#from_chapter_list_span_element' do
    subject { described_class.from_chapter_list_span_element(chapter_list, span_element) }

    let(:chapter_list) { double('chapter list', full_path: 'full_path') }
    let(:span_element) { double('span element') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterNullObject) }

    context 'ChapterList' do
      before { allow(chapter_list).to receive(:instance_of?).with(EPub::Unmarshaller::ChapterList).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterNullObject) }

      context 'Element' do
        let(:span_element) { Nokogiri::XML::Element.new('span', Nokogiri::XML::Document.parse(nil)) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.title).to be_empty }
        it { expect(subject.pages).to be_empty }

        context 'Span' do
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

          it { is_expected.to be_an_instance_of(described_class) }
          it { expect(subject.title).to eq 'Frontmatter' }
          it { expect(subject.pages).not_to be_empty }
          it { expect(subject.pages.length).to eq 2 }
          it { expect(subject.pages.first).to an_instance_of(EPub::Unmarshaller::Page) }
        end
      end
    end
  end
end
