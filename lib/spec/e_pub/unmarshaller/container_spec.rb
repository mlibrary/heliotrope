# frozen_string_literal: true

RSpec.describe EPub::Unmarshaller::Container do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }
    it { expect(subject.root_path).to eq '.' }
    it { expect(subject.rootfiles).to be_empty }
  end

  describe '#from_root_path' do
    subject { described_class.from_root_path(root_path) }

    let(:root_path) { double('root_path', to_str: 'root_path') }

    it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }

    context 'Root Path' do
      before { allow(root_path).to receive(:instance_of?).with(String).and_return(true) }

      it { is_expected.to be_an_instance_of(EPub::Unmarshaller::ContainerNullObject) }

      context 'Directory' do
        before { allow(Dir).to receive(:exist?).with(root_path).and_return(true) }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.root_path).to be root_path }
        it { expect(subject.rootfiles).to be_empty }

        context 'META-INF/container.xml exist' do
          before { allow(File).to receive(:open).with(File.join(root_path, 'META-INF/container.xml')).and_return(container_xml) }

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
            it { expect(subject.rootfiles).to be_empty }
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
            it { expect(subject.rootfiles).to contain_exactly instance_of(EPub::Unmarshaller::Rootfile) }
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
            it { expect(subject.rootfiles).to contain_exactly(instance_of(EPub::Unmarshaller::Rootfile), instance_of(EPub::Unmarshaller::Rootfile)) }
          end
        end
      end
    end
  end
end
