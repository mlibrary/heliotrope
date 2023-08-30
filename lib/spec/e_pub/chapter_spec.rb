# frozen_string_literal: true

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
  end
end
