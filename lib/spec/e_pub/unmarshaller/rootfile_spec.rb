# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Rootfile do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::RootfileNullObject) }
    it { expect(subject.label).to be_empty }
    it { expect(subject.content).to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }
  end

  describe '#from_container_rootfile_element' do
    subject { described_class.from_container_rootfile_element(container, rootfile_element) }

    let(:container) { double('container', root_path: 'root_path') }
    let(:rootfile_element) { double('rootfile element') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::RootfileNullObject) }

    context 'Container' do
      before { allow(container).to receive(:instance_of?).with(EPub::Unmarshaller::Container).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::RootfileNullObject) }

      context 'Element' do
        let(:rootfile_element) { Nokogiri::XML::Element.new('rootfile', Nokogiri::XML::Document.parse(nil)) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.label).to be_empty }
        it { expect(subject.content).to be_an_instance_of(EPub::Unmarshaller::ContentNullObject) }

        context 'Rootfile' do
          let(:rootfile_element) { container_doc.xpath(".//rootfile").first }
          let(:container_doc) { Nokogiri::XML::Document.parse(container_xml).remove_namespaces! }
          let(:container_xml) do
            <<-XML
              <?xml version="1.0" encoding="UTF-8"?>
              <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
                         xmlns:rendition="http://www.idpf.org/2013/rendition"
                         version="1.0">
                <rootfiles>
                  <rootfile full-path="OEBPS/content_fixed_scan.opf"
                            media-type="application/oebps-package+xml"
                            rendition:label="Page Scan"
                            rendition:layout="pre-paginated"
                            rendition:language="en-US"
                            rendition:media="(orientation:portrait)"
                            rendition:accessMode="visual"/>
                  <rootfile full-path="OEBPS/content_fixed_ocr.opf"
                            media-type="application/oebps-package+xml"
                            rendition:label="Text"
                            rendition:layout="pre-paginated"
                            rendition:language="en-US"
                            rendition:media="(orientation:portrait)"
                            rendition:accessMode="visual"/>
                </rootfiles>
              </container>
            XML
          end
          let(:content) { double('content') }

          before { allow(EPub::Unmarshaller::Content).to receive(:from_rootfile_full_path).with(subject, File.join(container.root_path, "OEBPS/content_fixed_scan.opf")).and_return(content) }

          it { is_expected.to be_an_instance_of(described_class) }
          it { expect(subject.label).to eq 'Page Scan' }
          it { expect(subject.content).to be content }
        end
      end
    end
  end
end
