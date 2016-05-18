require 'rails_helper'

describe FullName do
  describe '::build' do
    it 'concatenates the names' do
      expect(described_class.build('Shakespeare', 'W.')).to eq 'Shakespeare, W.'
      expect(described_class.build('Shakespeare', nil)).to eq 'Shakespeare'
      expect(described_class.build(nil, 'Madonna')).to eq 'Madonna'
      expect(described_class.build(nil, nil)).to eq ''
    end
  end
end
