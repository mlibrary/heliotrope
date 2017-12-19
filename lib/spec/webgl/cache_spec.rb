# frozen_string_literal: true

RSpec.describe Webgl::Cache do
  let(:id) { 'validnoid' }

  before { described_class.cache(id, './spec/fixtures/fake-game.unity') }
  after  { described_class.clear }

  describe '#cache' do
    subject { described_class.cache(id, './spec/fixtures/fake-game.unity') }
    it do
      expect(described_class.cached?(id)).to be true
      subject
      expect(described_class.cached?(id)).to be true
    end
  end

  describe '#purge' do
    subject { described_class.purge(id) }
    it do
      expect(described_class.cached?(id)).to be true
      subject
      expect(described_class.cached?(id)).to be false
    end
  end
end
