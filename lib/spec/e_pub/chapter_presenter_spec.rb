# frozen_string_literal: true

RSpec.describe EPub::ChapterPresenter do
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
  let(:chapter) { EPub::Chapter.send(:new, '1', 'Chapter1.xhtml', 'The Title', "/6/4/2[Chapter1]", Nokogiri::XML(chapter_doc)) }

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#title' do
    subject { described_class.send(:new, chapter).title }
    it 'returns the chapter title' do
      is_expected.to eq "The Title"
    end
  end

  describe '#href' do
    subject { described_class.send(:new, chapter).href }
    it 'returns the chapter href' do
      is_expected.to eq 'Chapter1.xhtml'
    end
  end

  describe '#paragraphs' do
    subject { described_class.send(:new, chapter).paragraphs }
    it 'returns the chapter paragraph presenters' do
      expect(subject.size).to eq 3
      expect(subject).to all(be_an_instance_of(EPub::ParagraphPresenter))
    end
  end

  describe "#cfi" do
    subject { described_class.send(:new, chapter).cfi }
    it "returns the (base) cfi" do
      is_expected.to eq "/6/4/2[Chapter1]"
    end
  end
end
