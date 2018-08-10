# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::ChapterList do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterListNullObject) }
    it { expect(subject.chapters).to be_empty }
  end

  describe '#from_content_chapter_full_path' do
    subject { described_class.from_content_chapter_list_full_path(content, full_path) }

    let(:content) { double('content') }
    let(:full_path) { double('full path') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterListNullObject) }

    context 'Content' do
      before { allow(content).to receive(:instance_of?).with(EPub::Unmarshaller::Content).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterListNullObject) }

      context 'Empty String' do
        let(:full_path) { '' }

        it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ChapterListNullObject) }
      end

      context 'Full Path' do
        let(:full_path) { 'chapterlist.xhtml' }
        let(:chapter_list_xml) do
          <<-XML
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
                      <a href="xhtml/00000001_fixed_scan.xhtml"/>
                    </li>
                    <li>
                      <a href="xhtml/00000002_fixed_scan.xhtml"/>
                    </li>
                  </ol>
                </li>
              </ol>
            </nav>
          XML
        end

        before { allow(File).to receive(:open).with(full_path).and_return(chapter_list_xml) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.chapters.length).to eq 1 }
      end
    end
  end
end
