# frozen_string_literal: true

RSpec.describe EPub::Section do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::SectionNullObject) }
    it { expect(subject.title).to be_empty }
    it { expect(subject.level).to eq 1 }
    it { expect(subject.cfi).to be_empty }
    it { expect(subject.downloadable?).to be false }
    it { expect(subject.pdf).to be_an_instance_of(Prawn::Document) }
  end

  describe '#from_cfi' do
    subject { described_class.from_cfi(publication, cfi) }

    let(:publication) { double('publication', multi_rendition: "yEs") }
    let(:cfi) { 'cfi' }
    let(:chapter) { double('chapter', title: 'title', basecfi: cfi, pdf: prawn) }
    let(:prawn) { Prawn::Document.new(page_size: "A4", page_layout: :portrait) }

    before do
      allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true)
      allow(EPub::Chapter).to receive(:from_cfi).with(publication, cfi).and_return(chapter)
    end

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.title).to eq 'title' }
    it { expect(subject.level).to eq 1 }
    it { expect(subject.cfi).to eq 'cfi' }
    it { expect(subject.downloadable?).to be true }
    it { expect(subject.pdf).to be_an_instance_of(Prawn::Document) }
  end

  describe '#from_chapter' do
    subject { described_class.from_chapter(publication, chapter) }

    let(:publication) { double('publication', multi_rendition: "Y") }
    let(:chapter) { double('chapter', title: 'title', basecfi: 'cfi', pdf: prawn) }
    let(:prawn) { Prawn::Document.new(page_size: "A4", page_layout: :portrait) }

    before do
      allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true)
      allow(chapter).to receive(:instance_of?).with(EPub::Chapter).and_return(true)
    end

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.title).to eq 'title' }
    it { expect(subject.level).to eq 1 }
    it { expect(subject.cfi).to eq 'cfi' }
    it { expect(subject.downloadable?).to be true }
    it { expect(subject.pdf).to be_an_instance_of(Prawn::Document) }
  end
end
