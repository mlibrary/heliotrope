# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Greensub do
  subject(:greensub) { described_class }

  let(:actor) { create(:user) }
  let(:individual) { create(:individual, identifier: actor.email) }
  let(:institutions) { [create(:institution), create(:institution)] }

  before do
    allow(actor).to receive(:individual).and_return(individual)
    allow(actor).to receive(:institutions).and_return(institutions)
  end

  it'#actor_product_list' do
    expect(greensub.actor_product_list(nil)).to be_empty

    expect(greensub.actor_product_list(actor)).to be_empty

    individual.lessee.products << create(:product)
    expect(greensub.actor_product_list(actor).count).to eq 1
    expect(greensub.actor_product_list(actor)).to match_array(individual.lessee.products)

    institutions.first.lessee.products << create(:product)
    expect(greensub.actor_product_list(actor).count).to eq 2
    expect(greensub.actor_product_list(actor)).to match_array((individual.lessee.products + institutions.first.lessee.products).uniq)

    institutions.last.lessee.products << institutions.first.lessee.products.first
    expect(greensub.actor_product_list(actor).count).to eq 2
    expect(greensub.actor_product_list(actor)).to match_array((individual.lessee.products + institutions.first.lessee.products).uniq)

    institutions.last.lessee.products << create(:product)
    expect(greensub.actor_product_list(actor).count).to eq 3
    expect(greensub.actor_product_list(actor)).to match_array((individual.lessee.products + institutions.first.lessee.products + institutions.last.lessee.products).uniq)

    individual.lessee.products << institutions.first.lessee.products.first
    expect(greensub.actor_product_list(actor).count).to eq 3
    expect(greensub.actor_product_list(actor)).to match_array((individual.lessee.products + institutions.first.lessee.products + institutions.last.lessee.products).uniq)

    individual.lessee.lessees_products.delete_all
    expect(greensub.actor_product_list(actor).count).to eq 2
    expect(greensub.actor_product_list(actor)).to match_array((institutions.first.lessee.products + institutions.last.lessee.products).uniq)

    institutions.first.lessee.products.delete_all
    expect(greensub.actor_product_list(actor).count).to eq 2 # institutions.last has both products anyway
    expect(greensub.actor_product_list(actor)).to match_array(institutions.last.lessee.products.uniq)

    institutions.last.lessee.products.delete_all
    expect(greensub.actor_product_list(actor)).to be_empty
  end
end
