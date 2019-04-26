# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RestfulSolr::Service do
  describe '#contains' do
    subject(:contains) { described_class.new.contains }

    before { ActiveFedora::Cleaner.clean! }

    it { is_expected.to eq([]) }

    it 'something' do
      monograph = create(:monograph)
      expect(contains.count).to eq(3)
      expect(contains).to include(monograph.id)
      objects = contains.map { |id| RestfulFedora.id_to_object(id) }
      expect(objects.any? { |obj| obj.is_a?(Monograph) }).to be true
      expect(objects.any? { |obj| obj.is_a?(Hydra::AccessControl) }).to be true
      expect(objects.any? { |obj| obj.is_a?(Hydra::AccessControls::Permission) }).to be true
    end
  end
end
