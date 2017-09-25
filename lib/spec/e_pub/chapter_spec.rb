# frozen_string_literal: true

require 'nokogiri'

RSpec.describe EPub::Chapter do
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
  let(:chapter_params) { ['1', 'Chapter1.xhtml', 'The Title', "/6/4/2[Chapter1]", Nokogiri::XML(chapter_doc)] }

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it 'returns a chapter null object' do
      is_expected.to be_an_instance_of(EPub::ChapterNullObject)
    end
  end

  describe '#title' do
    subject { described_class.send(:new, *chapter_params).title }

    it 'returns a string' do
      is_expected.to be_an_instance_of(String)
    end
  end

  describe '#paragraphs' do
    subject { described_class.send(:new, *chapter_params).paragraphs }

    it 'returns an array' do
      is_expected.to be_an_instance_of(Array)
    end
  end

  describe '#presenter' do
    subject { described_class.send(:new, *chapter_params).presenter }

    it 'returns a chapter presenter' do
      is_expected.to be_an_instance_of(EPub::ChapterPresenter)
    end
  end
end
