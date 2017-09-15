# frozen_string_literal: true

RSpec.describe EPub::ChapterPresenter do
  let(:chapter) { double("chapter") }

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#title' do
    subject { described_class.send(:new, chapter).title }
    let(:title) { double("title") }
    before { allow(chapter).to receive(:title).and_return(title) }
    it 'returns the chapter title' do
      is_expected.to eq title
    end
  end

  describe '#paragraphs' do
    subject { described_class.send(:new, chapter).paragraphs }
    let(:n) { 4 }
    let(:paragraphs) { [] }
    let(:presenters) { [] }
    before do
      allow(chapter).to receive(:paragraphs).and_return(paragraphs)
      n.times do |index|
        paragraphs << double("paragraph#{index}")
        presenters << double("presenter#{index}")
        allow(paragraphs[index]).to receive(:presenter).and_return(presenters[index])
      end
    end
    it 'returns the chapter paragraph presenters' do
      is_expected.to be_an_instance_of(Array)
      expect(subject.size).to eq n
      subject.each_with_index do |presenter, index|
        expect(presenter).to eq presenters[index]
      end
    end
  end
end
