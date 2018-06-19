# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Chapter do
  let(:publication) { double("publication") }
  let(:chapter_doc) do
    <<-EOT
    <html>
      <head>
        <title>Stuff about Things</title>
      </head>
      <body>
        <p>Chapter 1</p>
        <p>Human sacrifice, cats and dogs <i>living</i> together... <i>mass</i> hysteria!</p>
        <p>The one grand stage where he enacted all his various parts so manifold, was his vice-bench; a long rude ponderous table furnished with several vices, of different sizes, and both of iron and of wood. At all times except when whales were alongside, this bench was securely lashed athwartships against the rear of the Try-works.</p>
      </body>
    </html>
    EOT
  end
  let(:chapter_params) do
    { id: '1',
      href: 'Chapter1.xhtml',
      title: 'The Title',
      basecfi: "/6/4/2[Chapter1]",
      doc: Nokogiri::XML(chapter_doc),
      publication: publication }
  end

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::ChapterNullObject) }

    context "the null object" do
      describe "#title" do
        it { expect(subject.title).to be_empty }
      end

      describe "#paragraphs" do
        it { expect(subject.paragraphs).to eq [] }
      end

      describe "#presenter" do
        it { expect(subject.presenter).to be_an_instance_of(EPub::ChapterPresenter) }
      end

      describe "#downloadable" do
        it { expect(subject.downloadable?).to be false }
      end

      describe "#files_in_chapter" do
        it { expect(subject.files_in_chapter).to eq [] }
      end

      describe "#images_in_files" do
        it { expect(subject.images_in_files([])).to eq [] }
      end

      describe "#pdf" do
        it { expect(subject.pdf).to be_a Prawn::Document }
      end
    end
  end

  describe '#title' do
    subject { described_class.send(:new, chapter_params).title }

    it 'returns a string' do
      is_expected.to be_an_instance_of(String)
    end
  end

  describe '#paragraphs' do
    subject { described_class.send(:new, chapter_params).paragraphs }

    it 'returns an array' do
      is_expected.to be_an_instance_of(Array)
    end
  end

  describe '#presenter' do
    subject { described_class.send(:new, chapter_params).presenter }

    it 'returns a chapter presenter' do
      is_expected.to be_an_instance_of(EPub::ChapterPresenter)
    end
  end

  context "downloadable chapters for fixed layout epubs" do
    before do
      @noid = '999999997'
      @root_path = UnpackHelper.noid_to_root_path(@noid, 'epub')
      @file = './spec/fixtures/fake_epub_multi_rendition.epub'
      UnpackHelper.unpack_epub(@noid, @root_path, @file)
      UnpackHelper.create_search_index(@root_path)
      allow(EPub.logger).to receive(:info).and_return(nil)
    end

    after do
      FileUtils.rm_rf(Dir[File.join('./tmp', 'rspec_derivatives')])
    end

    describe "#from_cfi" do
      subject { described_class.from_cfi(publication, cfi) }

      let(:cfi) { '/6/2[xhtml00000003]!' }
      let(:publication) { EPub::Publication.from_directory(@root_path) }

      it { expect(subject).to be_a described_class }

      describe "#downloadable?" do
        it { expect(subject.downloadable?).to be true }
      end

      describe "#files_in_chapter" do
        it "lists the files (pages) in the chapter" do
          expect(subject.files_in_chapter).to eq ["./tmp/rspec_derivatives/99/99/99/99/7-epub/OEBPS/xhtml/00000003_fixed_scan.xhtml",
                                                  "./tmp/rspec_derivatives/99/99/99/99/7-epub/OEBPS/xhtml/00000004_fixed_scan.xhtml",
                                                  "./tmp/rspec_derivatives/99/99/99/99/7-epub/OEBPS/xhtml/00000005_fixed_scan.xhtml"]
        end
      end

      describe "#images_in_files" do
        it "lists the images in the files" do
          expect(subject.images_in_files(subject.files_in_chapter)).to eq ["./tmp/rspec_derivatives/99/99/99/99/7-epub/OEBPS/images/00000003.png",
                                                                           "./tmp/rspec_derivatives/99/99/99/99/7-epub/OEBPS/images/00000004.png",
                                                                           "./tmp/rspec_derivatives/99/99/99/99/7-epub/OEBPS/images/00000005.png"]
        end
      end

      describe "#pdf" do
        context "when downloadable" do
          it "creates the pdf object" do
            expect(subject.pdf).to be_a Prawn::Document
            expect(subject.pdf.page_count).to be 3
          end
        end
        context "when not downloadable" do
          it do
            allow(publication).to receive(:multi_rendition).and_return(false)
            allow(EPub.logger).to receive(:error).and_return(true)
            expect(subject.pdf).to be_a Prawn::Document
            expect(subject.pdf.page_count).to be 1 # one empty page
          end
        end
      end
    end
  end
end
