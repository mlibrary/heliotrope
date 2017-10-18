# frozen_string_literal: true

RSpec.describe EPub::PublicationPresenter do
  let(:publication) { double("publication") }

  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#id' do
    subject { described_class.send(:new, publication).id }
    let(:id) { double("id") }
    before { allow(publication).to receive(:id).and_return(id) }
    it 'returns the publication id' do
      is_expected.to eq id
    end
  end

  describe '#content_dir' do
    subject { described_class.send(:new, publication).content_dir }
    let(:content_file) { double("content_file") }

    context "when a directory exists" do
      before { allow(publication).to receive(:content_file).and_return("EPUB/content.opf") }
      it "returns the directory" do
        is_expected.to eq "EPUB"
      end
    end
    context "when no directory exists" do
      before { allow(publication).to receive(:content_file).and_return("content.opf") }
      it "returns ." do
        is_expected.to eq "."
      end
    end
  end

  describe '#chapters' do
    subject { described_class.send(:new, publication).chapters }
    let(:n) { 4 }
    let(:chapters) { [] }
    let(:presenters) { [] }
    before do
      allow(publication).to receive(:chapters).and_return(chapters)
      n.times do |index|
        chapters << double("chapter#{index}")
        presenters << double("presenter#{index}")
        allow(chapters[index]).to receive(:presenter).and_return(presenters[index])
        allow(chapters[index]).to receive(:title?).and_return(true)
      end
    end
    it 'returns the chapter presenters' do
      is_expected.to be_an_instance_of(Array)
      expect(subject.size).to eq n
      subject.each_with_index do |presenter, index|
        expect(presenter).to eq presenters[index]
      end
    end
  end
end
