# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TargetResourceResolver do
  subject { described_class.new.resolve(target) }

  let(:target) { { noid: noid, products: products } }
  let(:noid) { nil }
  let(:products) { nil }
  let(:any_target) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :any, resource_id: :any)) }

  it { is_expected.to be_an(Array) }
  it { is_expected.to eq([any_target]) }

  context 'noid' do
    let(:noid) { validnoid }
    let(:validnoid) { 'validnoid' }
    let(:noid_resource) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :noid, resource_id: validnoid)) }

    it { is_expected.to eq([any_target, noid_resource]) }
  end

  context 'products' do
    let(:products) { [product_first, product_last] }
    let(:product_first) { double('product_first', identifier: 'first') }
    let(:product_last) { double('product_last', identifier: 'last') }
    let(:product_first_resource) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :product, resource_id: product_first.identifier)) }
    let(:product_last_resource) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :product, resource_id: product_last.identifier)) }

    it { is_expected.to eq([any_target, product_first_resource, product_last_resource]) }
  end
end
