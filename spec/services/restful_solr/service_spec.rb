# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RestfulSolr::Service do
  describe '#contains' do
    subject(:contains) { described_class.new.contains }

    before { ActiveFedora::Cleaner.clean! }

    it { is_expected.to eq([]) }

    it 'something' do
      monograph = create(:monograph)
      expect(contains.count).to eq(5)
      expect(contains).to include(monograph.id)
      objects = contains.map { |id| RestfulFedora.id_to_object(id) }
      expect(objects).to contain_exactly(
        a_kind_of(Monograph),
        a_kind_of(Hydra::AccessControl),
        a_kind_of(Hydra::AccessControls::Permission),
        a_kind_of(Hydra::AccessControls::Embargo),
        a_kind_of(Hydra::AccessControls::Lease)
      )
    end
  end
end
