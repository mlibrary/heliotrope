# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Nav do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::NavNullObject) }
    it { expect(subject.tocs).to be_empty }
  end

  describe '#from_manifest_item_nav_href' do
    subject { nav }

    let(:nav) { described_class.from_manifest_item_nav_href(manifest_item_nav_href) }

    context 'Non Content and non String' do
      let(:manifest_item_nav_href) { double('manifest item nav href') }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::NavNullObject) }
    end

    context 'Null Content and empty String' do
      let(:manifest_item_nav_href) { '' }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::NavNullObject) }
    end

    context 'Content and item nav' do
      let(:manifest_item_nav_href) { 'toc.xhtml' }

      let(:toc_xml) do
        <<-XML
          <nav xmlns:epub="http://www.idpf.org/2007/ops" id="toc" epub:type="toc">
            <a href="1.xhtml">Title</a>
          </nav>
        XML
      end

      before do
        allow(File).to receive(:open).with(manifest_item_nav_href).and_return(toc_xml)
      end

      it { is_expected.to be_an_instance_of(described_class) }
      it { expect(subject.tocs).to contain_exactly instance_of(EPub::Unmarshaller::TOC) }
    end
  end
end
