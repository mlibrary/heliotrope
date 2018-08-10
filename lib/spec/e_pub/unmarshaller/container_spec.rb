# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Container do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }
    it { expect(subject.rootfile_elements).to be_empty }
  end

  describe '#from_root_path' do
    subject { described_class.from_root_path(root_path) }

    context 'nil root path' do
      let(:root_path) { nil }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }
    end

    context 'non String root path' do
      let(:root_path) { double('root_path') }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }
    end

    context 'directory String root path' do
      let(:root_path) { '/root/path' }

      before do
        allow(Dir).to receive(:exist?).with(root_path).and_return(dir_exist)
      end

      context 'directory does not exist' do
        let(:dir_exist) { false }

        it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }
      end

      context 'directory exist' do
        let(:dir_exist) { true }

        context 'META-INF/container.xml does not exist' do
          it { is_expected.to be_an_instance_of(described_class) }
          it { expect(subject.rootfile_elements).to be_empty }
        end

        context 'META-INF/container.xml exist' do
          before do
            allow(File).to receive(:open).with(File.join(root_path, 'META-INF/container.xml')).and_return(container_xml)
          end

          context 'no rootfile' do
            let(:container_xml) do
              <<-XML
              <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
                         xmlns:rendition="http://www.idpf.org/2013/rendition"
                         version="1.0">
                <rootfiles>
                </rootfiles>
              </container>
              XML
            end

            it { is_expected.to be_an_instance_of(described_class) }
            it { expect(subject.rootfile_elements).to be_empty }
          end

          context 'single rootfile' do
            let(:container_xml) do
              <<-XML
              <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
                         xmlns:rendition="http://www.idpf.org/2013/rendition"
                         version="1.0">
                <rootfiles>
                  <rootfile>
                  </rootfile>
                </rootfiles>
              </container>
              XML
            end
            it { is_expected.to be_an_instance_of(described_class) }
            it { expect(subject.rootfile_elements).not_to be_empty }
            it { expect(subject.rootfile_elements.length).to eq 1 }
          end

          context 'multiple rootfiles' do
            let(:container_xml) do
              <<-XML
            <container xmlns="urn:oasis:names:tc:opendocument:xmlns:container"
                       xmlns:rendition="http://www.idpf.org/2013/rendition"
                       version="1.0">
              <rootfiles>
                <rootfile>
                </rootfile>
                <rootfile>
                </rootfile>
              </rootfiles>
            </container>
              XML
            end
            it { is_expected.to be_an_instance_of(described_class) }
            it { expect(subject.rootfile_elements).not_to be_empty }
            it { expect(subject.rootfile_elements.length).to eq 2 }
          end
        end
      end
    end
  end
end
