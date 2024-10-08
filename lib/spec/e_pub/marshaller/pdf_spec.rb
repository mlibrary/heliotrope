# frozen_string_literal: true

RSpec.describe EPub::Marshaller::PDF do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Marshaller::PDFNullObject) }
  end

  describe '#from_publication_interval' do
    subject { described_class.from_publication_interval(publication, interval) }

    let(:publication) { double('publication') }
    let(:interval) { double('interval') }

    it { is_expected.to be_an_instance_of(EPub::Marshaller::PDFNullObject) }

    context 'Publication' do
      before { allow(publication).to receive(:instance_of?).with(EPub::Publication).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Marshaller::PDFNullObject) }

      context 'Interval' do
        before { allow(interval).to receive(:instance_of?).with(EPub::Interval).and_return(true) }

        context 'single rendition' do
          let(:publication) { double('publication', single_rendition?: true, multi_rendition?: false) }
          let(:interval) { double('interval') }

          it { is_expected.to be_an_instance_of(described_class) }
          it { expect(subject.document).to be_an_instance_of(Prawn::Document) }
          it { expect(subject.document.page_count).to be == 1 }
        end

        context 'multiple rendition' do
          let(:publication) do
            double('publication',
                   single_rendition?: false,
                   multi_rendition?: true,
                   renditions: [text_rendition, image_rendition])
          end
          let(:text_rendition) { double('text rendition', label: 'Text') }
          let(:image_rendition) do
            double('image rendition',
                   label: 'Page Scan',
                   intervals: [interval_1, interval_2])
          end
          let(:interval_1) { double('interval 1', cfi: 'cfi 1') }
          let(:interval_2) { double('interval 2', cfi: 'cfi 2', title: 'title 2', pages: [page_1, page_2]) }
          let(:page_1) { double('page 1', image: image_1) }
          let(:page_2) { double('page 2', image: image_2) }
          let(:image_1) { 'path/to/image/1' }
          let(:image_2) { 'path/to/image/2' }
          let(:interval) { double('interval', cfi: 'cfi 2', title: 'title 2') }
          let(:prawn_document) { double('prawn document', pages: []) }

          before do
            allow(Prawn::Document).to receive(:new).and_return(prawn_document)
            allow(prawn_document).to receive(:image).with(anything, fit: [512, 692]) do |arg|
              prawn_document.pages << arg
            end
          end

          it { is_expected.to be_an_instance_of(described_class) }
          it do
            expect(subject.document).to be prawn_document
            expect(prawn_document.pages.count).to eq 2
            expect(prawn_document.pages).to eq [image_1, image_2]
          end
        end
      end
    end
  end
end
