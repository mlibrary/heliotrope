# frozen_string_literal: true

RSpec.describe EPub::ParagraphNullObject do
  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end

  describe "html" do
    subject { described_class.null_object.html }
    it 'returns an empty string' do
      is_expected.to be_an_instance_of(String)
      is_expected.to eq '<p></p>'
    end
  end
end
