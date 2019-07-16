# frozen_string_literal: true

RSpec.describe PDFEbook::Interval do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(PDFEbook::IntervalNullObject) }
    it { expect(subject.title).to be_empty }
    it { expect(subject.level).to be_zero }
    it { expect(subject.cfi).to be_empty }
    it { expect(subject.downloadable?).to be false }
    it { expect(subject.pages).to be_empty }
  end

  describe '#from_title_level_cfi' do
    subject { described_class.from_title_level_cfi(title, level, cfi) }

    let(:title) { double('title') }
    let(:level) { double('level') }
    let(:cfi) { double('cfi') }
    let(:interval) { double('interval', cfi: cfi, title: title) }

    it { is_expected.to be_an_instance_of(PDFEbook::IntervalNullObject) }

    context 'Strings' do
      before do
        allow(cfi).to receive(:instance_of?).with(String).and_return(true)
        allow(title).to receive(:instance_of?).with(String).and_return(true)
      end

      it { is_expected.to be_an_instance_of(described_class) }
    end
  end
end
