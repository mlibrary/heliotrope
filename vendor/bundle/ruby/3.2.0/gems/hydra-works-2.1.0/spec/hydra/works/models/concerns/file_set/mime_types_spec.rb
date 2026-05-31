require 'spec_helper'

describe Hydra::Works::MimeTypes do
  subject { Hydra::Works::FileSet.new }

  describe '#pdf?' do
    before do
      allow(subject).to receive(:mime_type).and_return('application/pdf')
    end
    it 'is true' do
      expect(subject.pdf?).to be true
    end
  end

  describe '#image?' do
    before do
      allow(subject).to receive(:mime_type).and_return('image/jpeg')
    end
    it 'is true' do
      expect(subject.image?).to be true
    end
  end

  describe '#video?' do
    before do
      allow(subject).to receive(:mime_type).and_return('video/mp4')
    end
    it 'is true' do
      expect(subject.video?).to be true
    end
  end

  describe '#audio?' do
    before do
      allow(subject).to receive(:mime_type).and_return('audio/mp3')
    end
    it 'is true' do
      expect(subject.audio?).to be true
    end
  end

  describe '#office_document?' do
    before do
      allow(subject).to receive(:mime_type).and_return('application/msword')
    end
    it 'is true' do
      expect(subject.office_document?).to be true
    end
  end

  describe '#collection?' do
    it 'is false' do
      expect(subject.collection?).to be false
    end
  end
end
