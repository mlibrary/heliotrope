# frozen_string_literal: true

RSpec.describe MCSV::ManifestNullObject do
  describe '#new' do
    it 'private_class_method' do
      expect { is_expected }.to raise_error(NoMethodError)
    end
  end
end
