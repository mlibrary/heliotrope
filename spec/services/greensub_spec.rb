# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub do
  subject(:greensub) { described_class }

  let(:actor) { create(:user) }
  let(:individual) { create(:individual, identifier: actor.email) }
  let(:institutions) { [create(:institution), create(:institution)] }
  let(:products) { [create(:product), create(:product), create(:product)] }

  before do
    clear_grants_table
    allow(actor).to receive(:individual).and_return(individual)
    allow(actor).to receive(:institutions).and_return(institutions)
  end

  it { expect { greensub.actor_products(nil) }.to raise_error(NoMethodError) }

  it 'works' do
    expect(greensub.actor_products(actor)).to be_empty
    expect(individual.products).to be_empty
    expect(institutions[0].products).to be_empty
    expect(institutions[1].products).to be_empty
    expect(products[0].licensees).to be_empty
    expect(products[1].licensees).to be_empty
    expect(products[2].licensees).to be_empty

    individual.update_product_license(products[0])
    expect(individual.product_license?(products[0])).to be true
    expect(individual.products).to contain_exactly(products[0])
    expect(products[0].licensees).to contain_exactly(individual)
    expect(greensub.actor_products(actor).count).to eq 1
    expect(greensub.actor_products(actor)).to contain_exactly(products[0])

    institutions[0].update_product_license(products[1])
    expect(institutions[0].product_license?(products[1])).to be true
    expect(institutions[0].products).to contain_exactly(products[1])
    expect(products[1].licensees).to contain_exactly(institutions[0])
    expect(greensub.actor_products(actor).count).to eq 2
    expect(greensub.actor_products(actor)).to contain_exactly(products[0], products[1])

    institutions[1].update_product_license(products[2])
    expect(institutions[1].product_license?(products[2])).to be true
    expect(institutions[1].products).to contain_exactly(products[2])
    expect(products[2].licensees).to contain_exactly(institutions[1])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to contain_exactly(products[0], products[1], products[2])

    individual.update_product_license(products[1])
    expect(individual.product_license?(products[1])).to be true
    expect(individual.products).to contain_exactly(products[0], products[1])
    expect(products[1].licensees).to contain_exactly(individual, institutions[0])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to contain_exactly(products[0], products[1], products[2])

    institutions[0].update_product_license(products[0])
    expect(institutions[0].product_license?(products[0])).to be true
    expect(institutions[0].products).to contain_exactly(products[0], products[1])
    expect(products[0].licensees).to contain_exactly(individual, institutions[0])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to contain_exactly(products[0], products[1], products[2])

    individual.delete_product_license(products[0])
    expect(individual.product_license?(products[0])).to be false
    expect(individual.products).to contain_exactly(products[1])
    expect(products[0].licensees).to contain_exactly(institutions[0])
    expect(greensub.actor_products(actor).count).to eq 3
    expect(greensub.actor_products(actor)).to contain_exactly(products[0], products[1], products[2])

    institutions[0].delete_product_license(products[0])
    expect(institutions[0].product_license?(products[0])).to be false
    expect(institutions[0].products).to contain_exactly(products[1])
    expect(products[0].licensees).to be_empty
    expect(greensub.actor_products(actor).count).to eq 2
    expect(greensub.actor_products(actor)).to contain_exactly(products[1], products[2])

    institutions[0].delete_product_license(products[1])
    expect(institutions[0].product_license?(products[1])).to be false
    expect(institutions[0].products).to be_empty
    expect(products[1].licensees).to contain_exactly(individual)
    expect(greensub.actor_products(actor).count).to eq 2
    expect(greensub.actor_products(actor)).to contain_exactly(products[1], products[2])

    individual.delete_product_license(products[1])
    expect(individual.product_license?(products[1])).to be false
    expect(individual.products).to be_empty
    expect(products[1].licensees).to be_empty
    expect(greensub.actor_products(actor).count).to eq 1
    expect(greensub.actor_products(actor)).to contain_exactly(products[2])

    institutions[1].delete_product_license(products[2])
    expect(institutions[1].product_license?(products[2])).to be false
    expect(institutions[1].products).to be_empty
    expect(products[2].licensees).to be_empty
    expect(greensub.actor_products(actor).count).to eq 0
    expect(greensub.actor_products(actor)).to be_empty
  end

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
