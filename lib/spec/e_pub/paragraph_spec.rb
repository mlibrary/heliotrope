# frozen_string_literal: true

RSpec.describe EPub::Paragraph do
  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe '#null_object' do
    subject { described_class.null_object }

    it { is_expected.to be_an_instance_of(EPub::ParagraphNullObject) }
    it { expect { EPub::ParagraphNullObject.new }.to raise_error(NoMethodError) }
    it { expect(subject.html).to eq '<p></p>' }
  end

  describe '#text' do
    subject { described_class.send(:new, "I am paragraph text").text }

    it 'returns a string' do
      is_expected.to be_an_instance_of(String)
    end
  end
end
