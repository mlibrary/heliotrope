# frozen_string_literal: true

RSpec.describe EPub::Rendition do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::RenditionNullObject) }
    it { expect(subject.label).to eq EPub::Unmarshaller::Rootfile.null_object.label }
    it { expect(subject.intervals).to be_empty }
  end

  describe '#from_publication_unmarshaller_container_rootfile' do
    subject { described_class.from_publication_unmarshaller_container_rootfile(publication, unmarshaller_rootfile) }

    let(:publication) { double('publication', downloadable?: true) }
    let(:unmarshaller_rootfile) { double('unmarshaller rootfile', label: label, content: content, full_path: full_path) }
    let(:label) { double('label') }
    let(:full_path) { double('full path') }
    let(:content) { double('content', nav: nav) }
    let(:nav) { double('nav', tocs: [toc]) }
    let(:toc) { double('toc', id: 'toc', headers: [header]) }
    let(:header) { double('header', text: 'text', depth: 1, cfi: 'cfi', href: 'href') }
    let(:chapter) { double('chapter', pages: [page], downloadable_pages: [page]) }
    let(:page) { double('page', image: image) }
    let(:image) { double('image') }

    it { is_expected.to be_an_instance_of(EPub::RenditionNullObject) }

    context 'Publication' do
      before { allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::RenditionNullObject) }

      context 'Unmarshaller Rootfile' do
        before do
          allow(unmarshaller_rootfile).to receive(:instance_of?).with(EPub::Unmarshaller::Rootfile).and_return(true)
          allow(EPub::Unmarshaller::Content).to receive(:from_rootfile_full_path).with(unmarshaller_rootfile, full_path).and_return(content)
          allow(content).to receive(:idref_with_index_from_href).with(header.href).and_return(['idef', 1])
          allow(content).to receive(:chapter_from_title).with(header.text).and_return(chapter)
          allow(page).to receive(:instance_of?).with(EPub::Unmarshaller::Page).and_return(true)
        end

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.label).to be label }
        it { expect(subject.intervals.length).to eq 1 }
        it { expect(subject.intervals.first.title).to eq 'text' }
        it { expect(subject.intervals.first.level).to eq 1 }
        it { expect(subject.intervals.first.cfi).to eq '/6/2[idef]!/4/1:0' }
        it { expect(subject.intervals.first.downloadable?).to be true }
        it { expect(subject.intervals.first.pages.length).to eq 1 }
        it { expect(subject.intervals.first.pages.first).to be_an_instance_of(EPub::Page) }
        it { expect(subject.intervals.first.pages.first.image).to be image }
      end
    end
  end
end
