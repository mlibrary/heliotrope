# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::TOC do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::TOCNullObject) }
    it { expect(subject.id).to be_zero }
    it { expect(subject.headers).to be_empty }
  end

  describe '#from_nav_toc_element' do
    subject { toc }

    let(:toc) { described_class.from_nav_toc_element(toc_element) }

    context 'non toc element' do
      let(:toc_element) { double('toc element') }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::TOCNullObject) }
    end

    context 'toc element' do
      let(:toc_element) { double('toc element') }
      let(:anchor) { double('anchor') }
      let(:header) { double('header') }

      before do
        allow(toc_element).to receive(:instance_of?).with(Nokogiri::XML::Element).and_return(true)
        allow(toc_element).to receive(:[]).with('id').and_return('id')
        allow(toc_element).to receive(:xpath).with('.//a').and_return([anchor])
        allow(EPub::Unmarshaller::Header).to receive(:from_toc_anchor_element).with(anchor).and_return(header)
      end

      it { is_expected.to be_an_instance_of(described_class) }
      it { expect(subject.id).to eq 'id' }
      it { expect(subject.headers.length).to eq 1 }
      it { expect(subject.headers.first).to be header }
    end
  end
end
