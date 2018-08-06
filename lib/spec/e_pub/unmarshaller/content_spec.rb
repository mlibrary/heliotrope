# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Content do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    let(:full_dir) { File.dirname('./full/path/content.opf') }
    let(:href) { double('href') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }
    it { expect(subject.full_dir).to eq full_dir }
    it { expect(subject.idref_with_index_from_href(href)).to eq ['', 0] }
    it { expect(subject.nav).to be_an_instance_of(EPub::Unmarshaller::NavNullObject) }
  end

  describe '#from_full_path' do
    subject { described_class.from_full_path(full_path) }

    context 'non String' do
      let(:full_path) { double('full path') }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }
    end

    context 'empty String' do
      let(:full_path) { '' }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }
    end

    context 'full path' do
      let(:full_path) { './full/path/content.opf' }
      let(:full_dir) { File.dirname(full_path) }

      let(:content_doc) { Nokogiri::Slop(content_xml) }
      let(:content_xml) do
        <<-XML
          <content>
            <manifest>
              <item id="toc" href="toc.xhtml" properties="nav" />
              <item id="1" href="1.xhtml"/>
            </manifest>
            <spine>
              <itemref idref="1" />
            </spine>
          </content>
        XML
      end
      let(:toc_href) { content_doc.root.manifest.item.first["href"] }
      let(:toc_path) { File.join(full_dir, toc_href) }
      let(:href) { content_doc.root.manifest.item.last["href"] }
      let(:idref) { content_doc.root.spine.itemref["idref"] }

      let(:toc_doc) { Nokogiri::Slop(toc_xml) }
      let(:toc_xml) do
        <<-XML
          <nav>
            <a href="1.xhtml">Title</a>
          </nav>
        XML
      end

      before do
        allow(File).to receive(:open).with(full_path).and_return(content_xml)
        allow(File).to receive(:open).with(toc_path).and_return(toc_xml)
      end

      it { is_expected.to be_an_instance_of(described_class) }
      it { expect(subject.full_dir).to eq full_dir }
      it { expect(subject.idref_with_index_from_href(href)).to eq [idref, 1] }
      it { expect(subject.nav).to be_an_instance_of(EPub::Unmarshaller::Nav) }
    end
  end
end
