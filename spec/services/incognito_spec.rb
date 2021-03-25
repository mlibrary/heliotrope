# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Incognito do
  subject(:incognito) { described_class }

  let(:actor) { create(:user) }
  let(:admin) { false }
  let(:individual) { create(:individual, identifier: actor.email) }
  let(:institutions) { [institution, create(:institution)] }
  let(:institution) { create(:institution) }
  let(:product) { double('product') }

  before do
    allow(actor).to receive(:platform_admin?).and_return(admin)
    allow(actor).to receive(:individual).and_return(individual)
    allow(actor).to receive(:institutions).and_return(institutions)
    allow(Greensub::Individual).to receive(:find).with(individual.id).and_return(individual)
    allow(Greensub::Institution).to receive(:find).with(institution.id).and_return(institution)
    allow(individual).to receive(:products).and_return([product])
    allow(institution).to receive(:products).and_return([product])
  end

  it do
    expect(incognito.reset(actor)).to be true

    expect(incognito.allow_platform_admin?(actor)).to be true
    expect(incognito.allow_platform_admin(actor, false)).to be true
    expect(incognito.allow_platform_admin?(actor)).to be true

    expect(incognito.allow_ability_can?(actor)).to be true
    expect(incognito.allow_ability_can(actor, false)).to be true
    expect(incognito.allow_ability_can?(actor)).to be true

    expect(incognito.allow_action_permitted?(actor)).to be true
    expect(incognito.allow_action_permitted(actor, false)).to be true
    expect(incognito.allow_action_permitted?(actor)).to be true

    expect(incognito.sudo_actor?(actor)).to be false
    expect(incognito.sudo_actor(actor, true, individual.id, institution.id)).to be false
    expect(incognito.sudo_actor?(actor)).to be false
    expect(incognito.sudo_actor_individual(actor)).to be nil
    expect(incognito.sudo_actor_institution(actor)).to be nil
    expect(incognito.sudo_actor_products(actor)).to be_empty

    expect(incognito.developer?(actor)).to be false
    expect(incognito.developer(actor, true)).to be false
    expect(incognito.developer?(actor)).to be false
  end

  context 'platform_admin' do
    let(:admin) { true }

    it do
      expect(incognito.reset(actor)).to be true
      expect(incognito.allow_platform_admin?(actor)).to be true

      expect(incognito.allow_platform_admin(actor, false)).to be false
      expect(incognito.allow_platform_admin?(actor)).to be false

      expect(incognito.allow_platform_admin(actor)).to be true
      expect(incognito.allow_platform_admin?(actor)).to be true

      expect(incognito.allow_ability_can?(actor)).to be true
      expect(incognito.allow_ability_can(actor, false)).to be false
      expect(incognito.allow_ability_can?(actor)).to be false

      expect(incognito.allow_ability_can(actor)).to be true
      expect(incognito.allow_ability_can?(actor)).to be true

      expect(incognito.allow_action_permitted?(actor)).to be true
      expect(incognito.allow_action_permitted(actor, false)).to be false
      expect(incognito.allow_action_permitted?(actor)).to be false

      expect(incognito.allow_action_permitted(actor)).to be true
      expect(incognito.allow_action_permitted?(actor)).to be true

      expect(incognito.sudo_actor?(actor)).to be false
      expect(incognito.sudo_actor(actor, true, individual.id, institution.id)).to be true
      expect(incognito.sudo_actor?(actor)).to be true
      expect(incognito.sudo_actor_individual(actor)&.id).to be individual.id
      expect(incognito.sudo_actor_institution(actor)&.id).to be institution.id
      expect(incognito.sudo_actor_products(actor)).to eq [product]

      expect(incognito.developer?(actor)).to be false
      expect(incognito.developer(actor, true)).to be true
      expect(incognito.developer?(actor)).to be true

      expect(incognito.developer(actor)).to be false
      expect(incognito.developer?(actor)).to be false
    end

    context 'Individual.find Standard Error' do
      before { allow(Greensub::Individual).to receive(:find).with(individual.id).and_raise(StandardError) }

      it do
        expect(incognito.reset(actor)).to be true
        expect(incognito.sudo_actor?(actor)).to be false
        expect(incognito.sudo_actor(actor, true, individual.id, institution.id)).to be true
        expect(incognito.sudo_actor?(actor)).to be true
        expect(incognito.sudo_actor_individual(actor)&.id).to be nil
        expect(incognito.sudo_actor_institution(actor)&.id).to be institution.id
        expect(incognito.sudo_actor_products(actor)).to eq [product]
      end
    end

    context 'Institution.find Standard Error' do
      before { allow(Greensub::Institution).to receive(:find).with(institution.id).and_raise(StandardError) }

      it do
        expect(incognito.reset(actor)).to be true
        expect(incognito.sudo_actor?(actor)).to be false
        expect(incognito.sudo_actor(actor, true, individual.id, institution.id)).to be true
        expect(incognito.sudo_actor?(actor)).to be true
        expect(incognito.sudo_actor_individual(actor)&.id).to be individual.id
        expect(incognito.sudo_actor_institution(actor)&.id).to be nil
        expect(incognito.sudo_actor_products(actor)).to eq [product]

        expect(incognito.sudo_actor_institution(actor)).to be nil
      end
    end
  end
end
