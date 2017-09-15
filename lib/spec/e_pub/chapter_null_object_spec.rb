# frozen_string_literal: true

RSpec.describe EPub::ChapterNullObject do
  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe "#title" do
    subject { described_class.null_object.title }
    it 'returns an empty string' do
      is_expected.to be_an_instance_of(String)
      is_expected.to be_empty
    end
  end

  describe "#paragraphs" do
    subject { described_class.null_object.paragraphs }
    it 'returns an empty array' do
      is_expected.to be_an_instance_of(Array)
      is_expected.to be_empty
    end
  end
end
