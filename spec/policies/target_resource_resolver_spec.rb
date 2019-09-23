# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TargetResourceResolver do
  subject { described_class.new.expand(target) }

  let(:resolver) { Checkpoint::Resource::Resolver.new }
  let(:target) { double('target', resource_type: 'target_type', resource_id: 'target_id', component: component, products: products) }
  let(:component) { }
  let(:products) { [] }

  it { is_expected.to eq(resolver.expand(target)) }

  context 'component' do
    let(:component) { double('component', resource_type: 'component_type', resource_id: 'component_id') }

    it { is_expected.to eq(resolver.expand(target) + [resolver.convert(component)]) }

    context 'products' do
      let(:products) { [product_first, product_last] }
      let(:product_first) { double('product_first', resource_type: 'product_type', resource_id: 'product_first') }
      let(:product_last) { double('product_last', resource_type: 'product_type', resource_id: 'product_last') }

      it { is_expected.to eq(resolver.expand(target) + [resolver.convert(component), resolver.convert(product_first), resolver.convert(product_last)]) }
    end
  end
end
