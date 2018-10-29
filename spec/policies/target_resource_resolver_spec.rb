# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TargetResourceResolver do
  subject { described_class.new.resolve(target) }

  let(:target) { { noid: noid } }
  let(:noid) {}
  let(:any_target) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :any, resource_id: :any)) }
  let(:invalid_handle) { double('invalid_handle', valid?: false, noid: noid) }
  let(:valid_handle) { double('valid_handle', valid?: true, noid: noid) }
  let(:component) {}

  before do
    allow(NoidService).to receive(:from_noid).with(anything).and_return(invalid_handle)
    allow(NoidService).to receive(:from_noid).with('101010101').and_return(valid_handle)
    allow(Component).to receive(:find_by).with(noid: '101010101').and_return(component)
  end

  it { is_expected.to be_an(Array) }
  it { is_expected.to eq([any_target]) }

  context 'noid' do
    let(:noid) { '101010101' }
    let(:noid_resource) { Checkpoint::Resource.from(OpenStruct.new(resource_type: :noid, resource_id: noid)) }

    it { is_expected.to eq([any_target, noid_resource]) }

    context 'component' do
      let(:component) { Component.new(handle: HandleService.path(noid), products: products) }
      let(:component_resource) { Checkpoint::Resource.from(component) }
      let(:products) { [] }

      it { is_expected.to eq([any_target, noid_resource, component_resource]) }

      context 'products' do
        let(:products) { [product_first, product_last] }
        let(:product_first) { Product.new(identifier: 'first') }
        let(:product_first_resource) { Checkpoint::Resource.from(product_first) }
        let(:product_last) { Product.new(identifier: 'last') }
        let(:product_last_resource) { Checkpoint::Resource.from(product_last) }

        it { is_expected.to eq([any_target, noid_resource, component_resource, product_first_resource, product_last_resource]) }
      end
    end
  end
end
