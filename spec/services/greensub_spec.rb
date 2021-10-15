# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub do
  subject(:greensub) { described_class }

  describe '#product_include?' do
    subject { greensub.product_include?(product: product, entity: entity) }

    let(:product) { create(:product) }
    let(:component) { create(:component) }
    let(:entity) { double('entity', noid: noid) }
    let(:noid) { 'validnoid' }

    before { product.components << component }

    it { is_expected.to be false }

    context 'included' do
      let(:noid) { component.noid }

      it { is_expected.to be true }
    end
  end
end
