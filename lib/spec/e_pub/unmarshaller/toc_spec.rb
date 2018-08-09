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
    subject { described_class.from_nav_toc_element(nav, toc_element) }

    let(:nav) { double('nav') }
    let(:toc_element) { double('toc element') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::TOCNullObject) }

    context 'Nav' do
      before { allow(nav).to receive(:instance_of?).with(EPub::Unmarshaller::Nav).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::TOCNullObject) }

      context 'nav toc element' do
        let(:anchor) { double('anchor') }
        let(:header) { double('header') }

        before do
          allow(toc_element).to receive(:instance_of?).with(Nokogiri::XML::Element).and_return(true)
          allow(toc_element).to receive(:[]).with('id').and_return('id')
          allow(toc_element).to receive(:xpath).with('.//a').and_return([anchor])
          allow(EPub::Unmarshaller::Header).to receive(:from_toc_anchor_element).with(subject, anchor).and_return(header)
        end

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.id).to eq 'id' }
        it { expect(subject.headers.length).to eq 1 }
        it { expect(subject.headers.first).to be header }
      end
    end
  end
end
