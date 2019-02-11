# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RestfulFedora::Service do
  describe '#contains' do
    subject(:contains) { described_class.new.contains }

    before { ActiveFedora::Cleaner.clean! }

    it { is_expected.to eq([]) }

    it 'something' do
      monograph = create(:monograph)
      expect(contains.count).to eq(2)
      paths = contains.map { |uri| RestfulFedora.uri_to_path(uri) }
      ids = paths.map { |path| RestfulFedora.path_to_id(path) }
      expect(ids).to include(monograph.id)
      objects = ids.map { |id| RestfulFedora.id_to_object(id) }
      expect(objects[0].is_a?(Monograph) || objects[1].is_a?(Monograph)).to be true
      expect(objects[0].is_a?(Hydra::AccessControl) || objects[1].is_a?(Hydra::AccessControl)).to be true
    end
  end
end
