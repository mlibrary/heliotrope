# frozen_string_literal: true

RSpec.describe EPub::Paragraph do
  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it 'returns a chapter null object' do
      is_expected.to be_an_instance_of(EPub::ParagraphNullObject)
    end
  end

  describe '#text' do
    subject { described_class.send(:new, "I am paragraph text").text }

    it 'returns a string' do
      is_expected.to be_an_instance_of(String)
    end
  end

  describe '#presenter' do
    subject { described_class.send(:new, "I am paragraph text").presenter }

    it 'returns a chapter presenter' do
      is_expected.to be_an_instance_of(EPub::ParagraphPresenter)
    end
  end
end
