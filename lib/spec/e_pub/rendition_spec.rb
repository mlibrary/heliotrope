# frozen_string_literal: true

RSpec.describe EPub::Rendition do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::RenditionNullObject) }
    it { expect(subject.label.blank?).to be true }
    it { expect(subject.sections).to be_empty }
  end

  describe '#from_rootfile_element' do
    subject { described_class.from_rootfile_element(publication, rootfile_element) }

    let(:publication) { double('publication', root_path: '.', multi_rendition?: true) }
    let(:rootfile_element) { double('rootfile element', content: 'content') }
    let(:label) { double('label', text: 'text') }
    let(:full_path) { double('full path', value: './full/path/content.opf') }
    let(:content) { double('content', nav: nav) }
    let(:nav) { double('nav', tocs: [toc]) }
    let(:toc) { double('toc', id: 'toc', headers: [header]) }
    let(:header) { double('header', text: 'text', depth: 1, cfi: 'cfi', href: 'href') }

    before do
      allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true)
      allow(rootfile_element).to receive(:instance_of?).with(Nokogiri::XML::Element).and_return(true)
      allow(rootfile_element).to receive(:attribute).with('label').and_return(label)
      allow(rootfile_element).to receive(:attribute).with('full-path').and_return(full_path)
      allow(EPub::Unmarshaller::Content).to receive(:from_full_path).with(File.join(publication.root_path, full_path.value)).and_return(content)
      allow(content).to receive(:idref_with_index_from_href).with('href').and_return(['idef', 1])
    end

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.label).to be 'text' }
    it { expect(subject.sections.length).to eq 1 }
    it { expect(subject.sections.first.title).to eq 'text' }
    it { expect(subject.sections.first.level).to eq 1 }
    it { expect(subject.sections.first.cfi).to eq '/6/2[idef]!' }
    it { expect(subject.sections.first.downloadable?).to be true }
  end
end
