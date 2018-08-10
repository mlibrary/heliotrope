# frozen_string_literal: true

RSpec.describe EPub::Section do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::SectionNullObject) }
    it { expect(subject.title).to be_empty }
    it { expect(subject.level).to be_zero }
    it { expect(subject.cfi).to be_empty }
    it { expect(subject.downloadable?).to be false }
    it { expect(subject.pdf).to be_an_instance_of(Prawn::Document) }
  end

  describe '#from_cfi' do
    subject { described_class.from_cfi(publication, cfi) }

    let(:publication) { double('publication', sections: [section]) }
    let(:cfi) { 'cfi' }
    let(:section) { double('section', cfi: cfi) }

    before do
      allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true)
    end

    it { is_expected.to be section }
  end

  describe '#from_hash' do
    subject { described_class.from_hash(publication, args) }

    let(:publication) { double('publication', root_path: './') }
    let(:args) { { title: 'title', depth: 'depth', cfi: 'cfi', downloadable: true } }

    before do
      allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true)
      allow(EPub::Chapter).to receive(:from_cfi).with(publication, args[:cfi]).and_return(EPub::Chapter.null_object)
    end

    it { is_expected.to be_an_instance_of(described_class) }
    it { expect(subject.title).to eq 'title' }
    it { expect(subject.level).to eq 'depth' }
    it { expect(subject.cfi).to eq 'cfi' }
    it { expect(subject.downloadable?).to be true }
    it { expect(subject.pdf).to be_an_instance_of(Prawn::Document) }
  end
end
