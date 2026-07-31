# frozen_string_literal: true

RSpec.describe EPub::Publication do
  describe '#new' do
    it { expect { is_expected }.to raise_error(NoMethodError) }
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::PublicationNullObject) }
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

  describe "#chapters_from_file" do
    subject(:chapters) { described_class.send(:new, validator).chapters_from_file }

    let(:validator) do
      instance_double(EPub::Validator, id: 'noid', content_file: 'EPUB/content.opf', content: content, root_path: '/root')
    end
    let(:content) { Nokogiri::XML(content_xml).remove_namespaces! }
    let(:chapter_xhtml) { '<html><body><p>Some text</p></body></html>' }

    # see HELIO-4314
    context "when a manifest item @id has stray whitespace EPUBCheck would normalize" do
      # The manifest item's @id has a leading space, but the spine itemref's
      # @idref does not. An exact match would miss it; EPUBCheck strips the id
      # so the book validates, and we mirror that behavior.
      let(:content_xml) do
        <<-XML
          <package>
            <manifest>
              <item id=" Chapter01" href="xhtml/Chapter01.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
              <itemref idref="Chapter01"/>
            </spine>
          </package>
        XML
      end

      before do
        allow(File).to receive(:open).with('/root/EPUB/xhtml/Chapter01.xhtml').and_return(chapter_xhtml)
      end

      it "resolves the item and stores the trimmed id in the chapter and cfi" do
        expect(chapters.length).to eq 1
        expect(chapters.first.id).to eq 'Chapter01'
        expect(chapters.first.href).to eq 'xhtml/Chapter01.xhtml'
        expect(chapters.first.basecfi).to eq '/6/2[Chapter01]!'
      end
    end

    # see HELIO-4314
    context "when a spine idref does not resolve to any manifest item" do
      let(:content_xml) do
        <<-XML
          <package>
            <manifest>
              <item id="Chapter01" href="xhtml/Chapter01.xhtml" media-type="application/xhtml+xml"/>
            </manifest>
            <spine>
              <itemref idref="DoesNotExist"/>
            </spine>
          </package>
        XML
      end

      it "logs a warning and skips it rather than raising" do
        allow(EPub.logger).to receive(:warn)
        expect(chapters).to be_empty
        expect(EPub.logger).to have_received(:warn).with(/no manifest item matches spine idref 'DoesNotExist' in noid/)
      end
    end
  end
end
