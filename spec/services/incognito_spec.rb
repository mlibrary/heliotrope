# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Incognito do
  subject(:incognito) { described_class }

  let(:actor) { create(:user) }
  let(:admin) { false }
  let(:individual) { create(:individual, identifier: actor.email) }
  let(:institutions) { [institution1, institution2] }
  let(:institution1) { create(:institution) }
  let(:institution2) { create(:institution) }
  let(:institution_affiliation1) { create(:institution_affiliation, institution: institution1) }
  let(:institution_affiliation2) { create(:institution_affiliation, institution: institution2) }
  let(:license1) { instance_double(Greensub::FullLicense, 'license1') }
  let(:license2) { instance_double(Greensub::FullLicense, 'license2') }
  let(:product1) { instance_double(Greensub::Product, 'product1') }
  let(:product2) { instance_double(Greensub::Product, 'product2') }
  let(:press) { create(:press) }

  before do
    institution_affiliation1
    institution_affiliation2
    allow(actor).to receive(:platform_admin?).and_return(admin)
    allow(actor).to receive(:individual).and_return(individual)
    allow(actor).to receive(:institutions).and_return(institutions)
    allow(individual).to receive(:licenses).and_return([license1])
    allow(institution1).to receive(:licenses).and_return([license2])
    allow(individual).to receive(:products).and_return([product1])
    allow(institution1).to receive(:products).and_return([product2])
  end

  it do
    expect(incognito.reset(actor)).to be true

    expect(incognito.allow_platform_admin?(actor)).to be true
    expect(incognito.allow_platform_admin(actor, false)).to be true
    expect(incognito.allow_platform_admin?(actor)).to be true

    expect(incognito.allow_action_permitted?(actor)).to be true
    expect(incognito.allow_action_permitted(actor, false)).to be true
    expect(incognito.allow_action_permitted?(actor)).to be true

    expect(incognito.sudo_actor?(actor)).to be false
    expect(incognito.sudo_actor(actor, true, individual.id, institution_affiliation1.id)).to be false
    expect(incognito.sudo_actor?(actor)).to be false
    expect(incognito.sudo_actor_individual(actor)).to be nil
    expect(incognito.sudo_actor_institution(actor)).to be nil
    expect(incognito.sudo_actor_institution_affiliation(actor)).to be nil

    expect(incognito.sudo_role?(actor)).to be false
    expect(incognito.sudo_role(actor, true, press.id, 'admin')).to be false
    expect(incognito.sudo_role?(actor)).to be false
    expect(incognito.sudo_role_press(actor)).to be nil
    expect(incognito.sudo_role_press_role(actor)).to be ''

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

      expect(incognito.allow_action_permitted?(actor)).to be true
      expect(incognito.allow_action_permitted(actor, false)).to be false
      expect(incognito.allow_action_permitted?(actor)).to be false

      expect(incognito.allow_action_permitted(actor)).to be true
      expect(incognito.allow_action_permitted?(actor)).to be true

      expect(incognito.sudo_actor?(actor)).to be false
      expect(incognito.sudo_actor(actor, true, individual.id, institution_affiliation1.id)).to be true
      expect(incognito.sudo_actor?(actor)).to be true
      expect(incognito.sudo_actor_individual(actor)&.id).to be individual.id
      expect(incognito.sudo_actor_institution(actor)&.id).to be institution1.id
      expect(incognito.sudo_actor_institution_affiliation(actor)&.id).to be institution_affiliation1.id

      expect(incognito.sudo_role?(actor)).to be false
      expect(incognito.sudo_role(actor, true, press.id, 'admin')).to be true
      expect(incognito.sudo_role?(actor)).to be true
      expect(incognito.sudo_role_press(actor)&.id).to eq press.id
      expect(incognito.sudo_role_press_role(actor)).to eq 'admin'

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
        expect(incognito.sudo_actor(actor, true, individual.id, institution_affiliation1.id)).to be true
        expect(incognito.sudo_actor?(actor)).to be true
        expect(incognito.sudo_actor_individual(actor)&.id).to be nil
        expect(incognito.sudo_actor_institution(actor)&.id).to be institution1.id
        expect(incognito.sudo_actor_institution_affiliation(actor)&.id).to be institution_affiliation1.id
      end
    end

    context 'InstitutionAffiliation.find Standard Error' do
      before { allow(Greensub::InstitutionAffiliation).to receive(:find).with(institution_affiliation1.id).and_raise(StandardError) }

      it do
        expect(incognito.reset(actor)).to be true
        expect(incognito.sudo_actor?(actor)).to be false
        expect(incognito.sudo_actor(actor, true, individual.id, institution_affiliation1.id)).to be true
        expect(incognito.sudo_actor?(actor)).to be true
        expect(incognito.sudo_actor_individual(actor)&.id).to be individual.id
        expect(incognito.sudo_actor_institution(actor)&.id).to be nil
        expect(incognito.sudo_actor_institution_affiliation(actor)&.id).to be nil

        expect(incognito.sudo_actor_institution(actor)).to be nil
        expect(incognito.sudo_actor_institution_affiliation(actor)).to be nil
      end
    end

    context 'Press.find Standard Error' do
      before { allow(Press).to receive(:find).with(press.id).and_raise(StandardError) }

      it do
        expect(incognito.reset(actor)).to be true
        expect(incognito.sudo_role?(actor)).to be false
        expect(incognito.sudo_role(actor, true, press.id, 'admin')).to be true
        expect(incognito.sudo_role?(actor)).to be true
        expect(incognito.sudo_role_press(actor)&.id).to be nil
        expect(incognito.sudo_role_press_role(actor)).to eq 'admin'
      end
    end
  end
end
