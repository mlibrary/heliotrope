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
    it { expect(subject.pages).to be_empty }
  end

  describe '#from_rendition_cfi_title' do
    subject { described_class.from_rendition_cfi_title(rendition, cfi, title) }

    let(:rendition) { double('rendition', sections: [section]) }
    let(:cfi) { double('cfi') }
    let(:title) { double('title') }
    let(:section) { double('section', cfi: cfi, title: title) }

    it { is_expected.to be_an_instance_of(EPub::SectionNullObject) }

    context 'Rendition' do
      before { allow(rendition).to receive(:instance_of?).with(EPub::Rendition).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::SectionNullObject) }

      context 'Strings' do
        before do
          allow(cfi).to receive(:instance_of?).with(String).and_return(true)
          allow(title).to receive(:instance_of?).with(String).and_return(true)
        end

        it { is_expected.to be section }
      end
    end
  end

  describe '#from_rendition_args' do
    subject { described_class.from_rendition_args(rendition, args) }

    let(:rendition) { double('rendition', root_path: './') }
    let(:args) { double('args') }

    it { is_expected.to be_an_instance_of(EPub::SectionNullObject) }

    context 'Rendition' do
      before { allow(rendition).to receive(:instance_of?).with(EPub::Rendition).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::SectionNullObject) }

      context 'args' do
        let(:args) { { title: 'title', depth: 'depth', cfi: 'cfi', unmarshaller_chapter: unmarshaller_chapter } }
        let(:unmarshaller_chapter) { double('unmarshaller chapter', pages: pages, downloadable_pages: pages) }
        let(:pages) { double('pages', count: 2) }

        before { allow(pages).to receive(:map).and_return(pages) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.title).to eq 'title' }
        it { expect(subject.level).to eq 'depth' }
        it { expect(subject.cfi).to eq 'cfi' }
        it { expect(subject.downloadable?).to be true }
        it { expect(subject.pages).to be pages }
      end
    end
  end
end
