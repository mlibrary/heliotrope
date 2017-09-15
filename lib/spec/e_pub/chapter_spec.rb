# frozen_string_literal: true

RSpec.describe EPub::Chapter do
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
    subject { described_class.send(:new).title }

    it 'returns a string' do
      is_expected.to be_an_instance_of(String)
    end
  end

  describe '#paragraphs' do
    subject { described_class.send(:new).paragraphs }

    it 'returns an array' do
      is_expected.to be_an_instance_of(Array)
    end
  end

  describe '#presenter' do
    subject { described_class.send(:new).presenter }

    it 'returns a chapter presenter' do
      is_expected.to be_an_instance_of(EPub::ChapterPresenter)
    end
  end
end
