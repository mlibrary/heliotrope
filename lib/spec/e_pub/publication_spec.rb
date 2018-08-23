# frozen_string_literal: true

RSpec.describe EPub::Publication do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::PublicationNullObject) }
    it { expect(subject.downloadable?).to be false }
    it { expect(subject.single_rendition?).to be true }
    it { expect(subject.multi_rendition?).to be false }
    it { expect(subject.renditions).to contain_exactly instance_of(EPub::RenditionNullObject) }
    it { expect(subject.rendition).to be_an_instance_of(EPub::RenditionNullObject) }
    it { expect(subject.sections).to be subject.rendition.sections }
    it { expect(subject.sections).to eq EPub::Rendition.null_object.sections }
  end

  describe '#from_unmarshaller_container' do
    subject { described_class.from_unmarshaller_container(unmarshaller_container) }

    let(:unmarshaller_container) { double('unmarshaller container', rootfiles: rootfiles, rootfile: rootfiles.first) }
    let(:rootfiles) { [] }

    it { is_expected.to be_an_instance_of(EPub::PublicationNullObject) }

    context 'Unmarshaller Container' do
      let(:image_rootfile) { double('image rootfile') }
      let(:text_rootfile) { double('text rootfile') }
      let(:image_rendition) { double('image rendition', label: 'Page Scan', sections: [image_section]) }
      let(:text_rendition) { double('text rendition', label: 'Text', sections: [text_section]) }
      let(:image_section) { double('image section') }
      let(:text_section) { double('text section') }

      before do
        allow(unmarshaller_container).to receive(:instance_of?).with(EPub::Unmarshaller::Container).and_return(true)
        allow(EPub::Rendition).to receive(:from_publication_unmarshaller_container_rootfile).with(subject, image_rootfile).and_return(image_rendition)
        allow(EPub::Rendition).to receive(:from_publication_unmarshaller_container_rootfile).with(subject, text_rootfile).and_return(text_rendition)
      end

      context 'single rendition' do
        let(:rootfiles) { [text_rootfile] }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.downloadable?).to be false }
        it { expect(subject.single_rendition?).to be true }
        it { expect(subject.multi_rendition?).to be false }
        it { expect(subject.renditions.length).to eq 1 }
        it { expect(subject.rendition.label).to eq 'Text' }
        it { expect(subject.sections).to be subject.rendition.sections }
        it { expect(subject.sections.length).to eq 1 }
        it { expect(subject.sections.first).to be text_section }
      end

      context 'multi rendition' do
        let(:rootfiles) { [image_rootfile, text_rootfile] }

        it { is_expected.to be_an_instance_of(described_class) }
        it { expect(subject.downloadable?).to be true }
        it { expect(subject.single_rendition?).to be false }
        it { expect(subject.multi_rendition?).to be true }
        it { expect(subject.renditions.length).to eq 2 }
        it { expect(subject.rendition.label).to eq 'Text' }
        it { expect(subject.sections).to be subject.rendition.sections }
        it { expect(subject.sections.length).to eq 1 }
        it { expect(subject.sections.first).to be text_section }
      end
    end
  end

  describe "without a test epub" do
    let(:directory) { 'directory' }
    let(:noid) { 'validnoid' }
    let(:epub) { double("epub") }
    let(:validator) { double("validator") }
    let(:content) { double('content') }

    before do
      allow(File).to receive(:exist?).with(directory).and_return(true)
      allow(EPub::Validator).to receive(:from_directory).and_return(validator)
      allow(validator).to receive(:id).and_return(noid)
      allow(validator).to receive(:content_file).and_return(true)
      allow(validator).to receive(:content).and_return(content)
      allow(validator).to receive(:toc).and_return(true)
      allow(validator).to receive(:root_path).and_return(nil)
      allow(validator).to receive(:multi_rendition).and_return("no")
      allow(validator).to receive(:page_scan_content_file).and_return("")
      allow(validator).to receive(:ocr_content_file).and_return("")
      allow(EPub.logger).to receive(:info).and_return(nil)
    end

    # Class Methods

    describe '#null_object' do
      subject { described_class.null_object }

      let(:file_entry) { double('file_entry') }
      let(:query) { double("query") }

      it { is_expected.to be_an_instance_of(EPub::PublicationNullObject) }
      it { expect { EPub::PublicationNullObject.new }.to raise_error(NoMethodError) }
      it { expect(subject.id).to eq 'null_epub' }
      it { expect(subject.chapters).to be_an_instance_of(Array) }
      it { expect(subject.chapters).to be_empty }
      it { expect(subject.read(file_entry)).to be_a(String) }
      it { expect(subject.read(file_entry)).to be_empty }
      it { expect(subject.file(file_entry)).to be_a(String) }
      it { expect(subject.file(file_entry)).to be_empty }
      it { expect(subject.search(query)).to be_a(Hash) }
      it { expect(subject.search(query)[:q]).to eq query }
      it { expect(subject.search(query)[:search_results]).to eq([]) }
    end

    # Instance Methods

    describe '#id' do
      subject { described_class.from_directory(directory).id }

      it 'returns noid' do
        is_expected.to eq noid
      end
    end

    describe '#search' do
      subject { instance.search(query) }

      let(:instance) { described_class.from_directory(directory) }
      let(:search)  { double("search") }
      let(:query) { double("query") }
      let(:results) { double("results") }

      before do
        allow(EPub::Search).to receive(:new).with(instance).and_return(search)
        allow(search).to receive(:search).with(query).and_return(results)
      end

      context 'epubs search service returns results' do
        it 'returns results' do
          is_expected.to eq results
        end
      end

      context 'epubs search service raises standard error' do
        before do
          allow(search).to receive(:search).with(query).and_raise(StandardError)
          @message = 'message'
          allow(EPub.logger).to receive(:info).with(any_args) { |value| @message = value }
        end

        it 'returns null object query' do
          is_expected.not_to eq results
          is_expected.to eq described_class.null_object.search(query)
          expect(@message).not_to eq 'message'
          expect(@message).to eq 'Publication.search(#[Double "query"]) in publication validnoid raised StandardError'
        end
      end
    end
  end

  describe "with a test epub" do
    context "using #from_directory with root_path" do
      before do
        @noid = '999999993'
        @root_path = UnpackHelper.noid_to_root_path(@noid, 'epub')
        @file = './spec/fixtures/fake_epub01.epub'
        UnpackHelper.unpack_epub(@noid, @root_path, @file)
        UnpackHelper.create_search_index(@root_path)
        allow(EPub.logger).to receive(:info).and_return(nil)
      end

      after do
        FileUtils.rm_rf(Dir[File.join('./tmp', 'rspec_derivatives')])
      end

      describe "#file" do
        subject { described_class.from_directory(@root_path).file(epub_file) }

        let(:epub_file) { "META-INF/container.xml" }

        it "returns the file path" do
          expect(subject).to eq "./tmp/rspec_derivatives/99/99/99/99/3-epub/META-INF/container.xml"
        end
      end

      describe "#chapters" do
        subject { described_class.from_directory(@root_path) }

        it "has 3 chapters" do
          expect(subject.chapters.count).to be 3
        end

        describe "the first chapter" do
          # It's a little wrong to test this here, but Publication has the logic
          # that populates the Chapter object, so it's here. For now.
          subject { described_class.from_directory(@root_path).chapters[0] }

          it "has the id of" do
            expect(subject.id).to eq "Chapter01"
          end
          it "has the href of" do
            expect(subject.href).to eq "xhtml/Chapter01.xhtml"
          end
          it "has the title of" do
            expect(subject.title).to eq 'Damage report!'
          end
          it "has the basecfi of" do
            expect(subject.basecfi).to eq '/6/2[Chapter01]!'
          end
          it "has the chapter doc" do
            expect(subject.doc.name).to eq 'document'
            expect(subject.doc.xpath("//p")[2].text).to eq "Computer, belay that order"
          end
        end
      end
    end
  end
end
