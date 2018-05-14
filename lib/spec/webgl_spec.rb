# frozen_string_literal: true

RSpec.describe Webgl do
  describe '#self.logger' do
    it 'is a Logger' do
      expect(described_class.logger).to be_an_instance_of(Logger)
    end
  end
end
