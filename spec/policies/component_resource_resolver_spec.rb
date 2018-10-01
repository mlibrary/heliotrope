# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ComponentResourceResolver do
  subject { described_class.new.resolve(target) }

  let(:target) { double('target', products: products) }
  let(:products) { [] }
  let(:product_first) { double('product_first', identifier: 'first') }
  let(:product_last) { double('product_last', identifier: 'last') }
  let(:product_first_resource) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :product, resource_id: product_first.identifier)) }
  let(:product_last_resource) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :product, resource_id: product_last.identifier)) }

  it { is_expected.to be_an(Array) }
  it { is_expected.to be_empty }

  context 'products' do
    let(:products) { [product_first, product_last] }

    it { is_expected.to eq([product_first_resource, product_last_resource]) }
  end
end
