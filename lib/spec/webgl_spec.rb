# frozen_string_literal: true

RSpec.describe Webgl do
  describe '#self.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to be_an_instance_of(Logger)
    end
  end

  describe '#self.root' do
    it 'has a default' do
      expect(described_class.root).to eq './tmp/webgl'
    end
  end

  describe '#self.root=' do
    before { described_class.root = './' }
    it 'sets the root' do
      expect(described_class.root).to eq './'
    end
  end
end
