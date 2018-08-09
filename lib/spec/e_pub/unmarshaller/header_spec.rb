# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Header do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::HeaderNullObject) }
    it { expect(subject.href).to be_empty }
    it { expect(subject.text).to be_empty }
    it { expect(subject.depth).to be_zero }
  end

  describe '#from_toc_anchor_element' do
    subject { described_class.from_toc_anchor_element(toc, anchor_element) }

    let(:toc) { double('toc') }
    let(:anchor_element) { double('anchor node') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::HeaderNullObject) }

    context 'TOC' do
      before { allow(toc).to receive(:instance_of?).with(EPub::Unmarshaller::TOC).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::HeaderNullObject) }

      context 'Anchor' do
        let(:toc_element) { Nokogiri::XML::Document.parse(toc_xml) }
        let(:anchor_element) { toc_element.root.xpath('//a').first }
        let(:toc_xml) do
          <<-XML
          <nav>
            <ol>
              <li>
                <a href="1.xhtml">Title</a>
              </li>
            </ol>
          </nav>
          XML
        end

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.href).to eq '1.xhtml' }
        it { expect(subject.text).to eq 'Title' }
        it { expect(subject.depth).to eq 1 }
      end
    end
  end
end
