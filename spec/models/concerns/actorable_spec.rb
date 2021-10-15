# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Actorable do
  let(:actor) { create(:user, request_attributes: { dlpsInstitutionId: institutions.map(&:identifier) }) }
  let(:sudo_actor) { create(:platform_admin) }
  let(:individual) { create(:individual, identifier: actor.email, email: actor.email) }
  let(:institutions) { 2.times.reduce([]) { |rv, obj| rv << create(:institution) } }
  let(:institutions_affiliations) { institutions.map { |institution| create(:institution_affiliation, institution_id: institution.id, dlps_institution_id: institution.identifier) } }
  let(:products) { 3.times.reduce([]) { |rv, obj| rv << create(:product) } }

  before do
    clear_grants_table
    institutions_affiliations
    Incognito.reset(sudo_actor)
    Incognito.allow_platform_admin(sudo_actor, false)
    Incognito.sudo_actor(sudo_actor, true, individual.id, institutions_affiliations.last.id)
    sudo_actor.reload
  end

  it 'works' do
    expect(individual.products).to be_empty
    expect(institutions[0].products).to be_empty
    expect(institutions[1].products).to be_empty
    expect(products[0].licensees).to be_empty
    expect(products[1].licensees).to be_empty
    expect(products[2].licensees).to be_empty

    individual.create_product_license(products[0])
    expect(individual.find_product_license(products[0])).not_to be nil
    expect(individual.products).to contain_exactly(products[0])
    expect(products[0].licensees).to contain_exactly(individual)
    expect(actor.products.count).to eq 1
    expect(actor.products).to contain_exactly(products[0])
    expect(sudo_actor.products.count).to eq 1
    expect(sudo_actor.products).to contain_exactly(products[0])

    institutions[0].create_product_license(products[1])
    expect(institutions[0].find_product_license(products[1])).not_to be nil
    expect(institutions[0].products).to contain_exactly(products[1])
    expect(products[1].licensees).to contain_exactly(institutions[0])
    expect(actor.products.count).to eq 2
    expect(actor.products).to contain_exactly(products[0], products[1])
    expect(sudo_actor.products.count).to eq 1
    expect(sudo_actor.products).to contain_exactly(products[0])

    institutions[1].create_product_license(products[2])
    expect(institutions[1].find_product_license(products[2])).not_to be nil
    expect(institutions[1].products).to contain_exactly(products[2])
    expect(products[2].licensees).to contain_exactly(institutions[1])
    expect(actor.products.count).to eq 3
    expect(actor.products).to contain_exactly(products[0], products[1], products[2])
    expect(sudo_actor.products.count).to eq 2
    expect(sudo_actor.products).to contain_exactly(products[0], products[2])

    individual.create_product_license(products[1])
    expect(individual.find_product_license(products[1])).not_to be nil
    expect(individual.products).to contain_exactly(products[0], products[1])
    expect(products[1].licensees).to contain_exactly(individual, institutions[0])
    expect(actor.products.count).to eq 3
    expect(actor.products).to contain_exactly(products[0], products[1], products[2])
    expect(sudo_actor.products.count).to eq 3
    expect(sudo_actor.products).to contain_exactly(products[0], products[1], products[2])

    institutions[0].create_product_license(products[0])
    expect(institutions[0].find_product_license(products[0])).not_to be nil
    expect(institutions[0].products).to contain_exactly(products[0], products[1])
    expect(products[0].licensees).to contain_exactly(individual, institutions[0])
    expect(actor.products.count).to eq 3
    expect(actor.products).to contain_exactly(products[0], products[1], products[2])
    expect(sudo_actor.products.count).to eq 3
    expect(sudo_actor.products).to contain_exactly(products[0], products[1], products[2])

    individual.delete_product_license(products[0])
    expect(individual.find_product_license(products[0])).to be nil
    expect(individual.products).to contain_exactly(products[1])
    expect(products[0].licensees).to contain_exactly(institutions[0])
    expect(actor.products.count).to eq 3
    expect(actor.products).to contain_exactly(products[0], products[1], products[2])
    expect(sudo_actor.products.count).to eq 2
    expect(sudo_actor.products).to contain_exactly(products[1], products[2])

    institutions[0].delete_product_license(products[0])
    expect(institutions[0].find_product_license(products[0])).to be nil
    expect(institutions[0].products).to contain_exactly(products[1])
    expect(products[0].licensees).to be_empty
    expect(actor.products.count).to eq 2
    expect(actor.products).to contain_exactly(products[1], products[2])
    expect(sudo_actor.products.count).to eq 2
    expect(sudo_actor.products).to contain_exactly(products[1], products[2])

    institutions[0].delete_product_license(products[1])
    expect(institutions[0].find_product_license(products[1])).to be nil
    expect(institutions[0].products).to be_empty
    expect(products[1].licensees).to contain_exactly(individual)
    expect(actor.products.count).to eq 2
    expect(actor.products).to contain_exactly(products[1], products[2])
    expect(sudo_actor.products.count).to eq 2
    expect(sudo_actor.products).to contain_exactly(products[1], products[2])

    individual.delete_product_license(products[1])
    expect(individual.find_product_license(products[1])).to be nil
    expect(individual.products).to be_empty
    expect(products[1].licensees).to be_empty
    expect(actor.products.count).to eq 1
    expect(actor.products).to contain_exactly(products[2])
    expect(sudo_actor.products.count).to eq 1
    expect(sudo_actor.products).to contain_exactly(products[2])

    institutions[1].delete_product_license(products[2])
    expect(institutions[1].find_product_license(products[2])).to be nil
    expect(institutions[1].products).to be_empty
    expect(products[2].licensees).to be_empty
    expect(actor.products.count).to eq 0
    expect(actor.products).to be_empty
    expect(sudo_actor.products.count).to eq 0
    expect(sudo_actor.products).to be_empty
  end
end
