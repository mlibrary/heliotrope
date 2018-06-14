# frozen_string_literal: true

RSpec.describe EPub::ChapterPresenter do
  subject { described_class.send(:new, chapter) }

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
  let(:chapter) do
    EPub::Chapter.send(:new,
                       id: '1',
                       href: 'Chapter1.xhtml',
                       title: 'The Title',
                       basecfi: "/6/4/2[Chapter1]",
                       doc: Nokogiri::XML(chapter_doc),
                       publication: publication)
  end

  describe '#new' do
    it 'private_class_method' do
      expect { described_class.new }.to raise_error(NoMethodError)
    end
  end

  describe '#title' do
    it 'returns the chapter title' do
      expect(subject.title).to eq "The Title"
    end
  end

  describe '#href' do
    it 'returns the chapter href' do
      expect(subject.href).to eq 'Chapter1.xhtml'
    end
  end

  describe '#paragraphs' do
    it 'returns the chapter paragraph presenters' do
      expect(subject.paragraphs.size).to eq 3
      expect(subject.paragraphs).to all(be_an_instance_of(EPub::ParagraphPresenter))
    end
  end

  describe "#cfi" do
    it "returns the (base) cfi" do
      expect(subject.cfi).to eq "/6/4/2[Chapter1]"
    end
  end

  describe "#downloadable" do
    context "when the epub is not fixed layout" do
      it "returns false" do
        allow(publication).to receive(:multi_rendition).and_return("no")
        expect(subject.downloadable?).to be false
      end
    end
    context "when the epub is fixed layout" do
      it "returns true" do
        allow(publication).to receive(:multi_rendition).and_return("yes")
        expect(subject.downloadable?).to be true
      end
    end
  end

  describe "#blurb" do
    context "when the epub is not fixed layout" do
      it "returns some text (usually the first few paragraphs)" do
        allow(publication).to receive(:multi_rendition).and_return("no")
        expect(subject.blurb.starts_with?("<p>Chapter 1</p><p>Human sacrifice, cats and dogs living together")).to be true
      end
    end
    context "when the epub is fixed layout" do
      it "returns an empty string" do
        allow(publication).to receive(:multi_rendition).and_return("yes")
        expect(subject.blurb).to be ""
      end
    end
  end
end
