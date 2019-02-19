# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Content do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }
    it { expect(subject.idref_with_index_from_href('href')).to eq ['', 0] }
    it { expect(subject.chapter_from_title('title')).to be_an_instance_of(EPub::Unmarshaller::ChapterNullObject) }
    it { expect(subject.nav).to be_an_instance_of(EPub::Unmarshaller::NavNullObject) }
    it { expect(subject.chapter_list).to be_an_instance_of(EPub::Unmarshaller::ChapterListNullObject) }
  end

  describe '#from_rootfile_full_path' do
    subject { described_class.from_rootfile_full_path(rootfile, full_path) }

    let(:rootfile) { double('rootfile') }
    let(:full_path) { '' }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }

    context 'Rootfile' do
      before { allow(rootfile).to receive(:instance_of?).with(EPub::Unmarshaller::Rootfile).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }

      context 'Empty String' do
        it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }

        context 'Full Path' do
          let(:full_path) { './OEBPS/content.opf' }

          it { is_expected.to be_an_instance_of(described_class) }
          it { expect(subject.idref_with_index_from_href('href')).to eq ['', 0] }
          it { expect(subject.chapter_from_title('title')).to be_an_instance_of(EPub::Unmarshaller::ChapterNullObject) }
          it { expect(subject.nav).to be_an_instance_of(EPub::Unmarshaller::NavNullObject) }
          it { expect(subject.chapter_list).to be_an_instance_of(EPub::Unmarshaller::ChapterListNullObject) }

          context 'Content' do
            let(:full_dir) { File.dirname(full_path) }

            let(:content_doc) { Nokogiri::Slop(content_xml) }
            let(:content_xml) do
              <<-XML
                <content>
                  <manifest>
                    <item id="toc" href="toc.xhtml" properties="nav" />
                    <item id="1" href="1.xhtml"/>
                    <item id="chapterlist" href="chapterlist_fixed_scan.xhtml" />
                  </manifest>
                  <spine>
                    <itemref idref="1" />
                  </spine>
                </content>
              XML
            end
            let(:toc_href) { content_doc.root.manifest.item("[@id='toc']")["href"] }
            let(:toc_path) { File.join(full_dir, toc_href) }
            let(:href) { toc_doc.xpath('//a').first.attributes['href'].value }
            let(:idref) { content_doc.root.spine.itemref["idref"] }

            let(:toc_doc) { Nokogiri::Slop(toc_xml) }
            let(:toc_xml) do
              <<-XML
                <nav>
                  <a href="1.xhtml#one">Title</a>
                </nav>
              XML
            end

            let(:chapter_list_href) { content_doc.root.manifest.item("[@id='chapterlist']")["href"] }
            let(:chapter_list_path) { File.join(full_dir, chapter_list_href) }
            let(:chapter_list_doc) { Nokogiri::Slop(chapter_list_xml) }
            let(:chapter_list_xml) do
              <<-XML
                <nav>
                  <a href="chapterlist.xhtml">Chapter List</a>
                </nav>
              XML
            end
            let(:chapter) do
              <<-CHAPTER
              <html>
                <head>
                  <title>On Things</title>
                </head>
                <body>
                  <section id="one">
                    <p>Some stuff about things</p>
                  </section>
                </body>
              </html>
              CHAPTER
            end
            let(:index) { 1 }

            before do
              allow(File).to receive(:open).with('')
              allow(File).to receive(:open).with('./META-INF/container.xml')
              allow(File).to receive(:open).with(full_path).and_return(content_xml)
              allow(File).to receive(:open).with(toc_path).and_return(toc_xml)
              allow(File).to receive(:open).with(chapter_list_path).and_return(chapter_list_xml)
              allow(File).to receive(:open).with("./OEBPS/1.xhtml").and_return(chapter)
            end

            it { expect(subject.idref_with_index_from_href(href)).to eq [idref, 1] }
            it { expect(subject.chapter_from_title('title')).to be_an_instance_of(EPub::Unmarshaller::ChapterNullObject) }
            it { expect(subject.nav).to be_an_instance_of(EPub::Unmarshaller::Nav) }
            it { expect(subject.chapter_list).to be_an_instance_of(EPub::Unmarshaller::ChapterList) }
          end
        end
      end
    end
  end
end
