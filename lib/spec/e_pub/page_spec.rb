# frozen_string_literal: true

RSpec.describe EPub::Page do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::PageNullObject) }
    it { expect(subject.image).to be_empty }
  end

  describe '#from_interval_unmarshaller_page' do
    subject { described_class.from_interval_unmarshaller_page(interval, unmarshaller_page) }

    let(:interval) { double('interval') }
    let(:unmarshaller_page) { double('unmarshaller page', image: image) }
    let(:image) { double('image') }

    it { is_expected.to be_an_instance_of(EPub::PageNullObject) }

    context 'Interval' do
      before { allow(interval).to receive(:instance_of?).with(EPub::Interval).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::PageNullObject) }

      context 'Unmarshaller Page' do
        before { allow(unmarshaller_page).to receive(:instance_of?).with(EPub::Unmarshaller::Page).and_return(true) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.image).to be image }
      end
    end
  end
end
