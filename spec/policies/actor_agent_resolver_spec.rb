# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorAgentResolver do
  subject { described_class.new.expand(actor) }

  let(:resolver) { Checkpoint::Agent::Resolver.new }
  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id') }

  it { is_expected.to eq(resolver.expand(actor)) }

  context 'world institution' do
    let(:world_institution) { instance_double(Greensub::Institution, 'world_institution', agent_type: 'institution_type', agent_id: 'institution_world') }

    before { allow(Greensub::Institution).to receive(:where).with(identifier: Settings.world_institution_identifier).and_return [world_institution] }

    it { is_expected.to eq(resolver.expand(actor)) }
  end

  context 'anonymous user' do
    let(:actor) { instance_double(Anonymous, 'actor', agent_type: 'actor_type', agent_id: 'actor_id', individual: individual, institutions: institutions) }
    let(:individual) { }
    let(:institutions) { [] }

    context 'world institution' do
      let(:world_institution) { instance_double(Greensub::Institution, 'world_institution', agent_type: 'institution_type', agent_id: 'institution_world') }

      before { allow(Greensub::Institution).to receive(:where).with(identifier: Settings.world_institution_identifier).and_return [world_institution] }

      it { is_expected.to eq(resolver.expand(actor) + [resolver.convert(world_institution)]) }
    end

    context 'individual' do
      let(:individual) { instance_double(Greensub::Individual, 'individual', agent_type: 'individual_type', agent_id: 'individual_id') }

      it { is_expected.to eq(resolver.expand(actor) + [resolver.convert(individual)]) }

      context 'institutions' do
        let(:institutions) { [institution_first, institution_last] }
        let(:institution_first) { instance_double(Greensub::Institution, 'institution_first', agent_type: 'institution_type', agent_id: 'institution_first') }
        let(:institution_last) { instance_double(Greensub::Institution, 'institution_last', agent_type: 'institution_type', agent_id: 'institution_last') }

        it { is_expected.to eq(resolver.expand(actor) + [resolver.convert(individual), resolver.convert(institution_first), resolver.convert(institution_last)]) }

        context 'world institution' do
          let(:world_institution) { instance_double(Greensub::Institution, 'world_institution', agent_type: 'institution_type', agent_id: 'institution_world') }

          before { allow(Greensub::Institution).to receive(:where).with(identifier: Settings.world_institution_identifier).and_return [world_institution] }

          it { is_expected.to eq(resolver.expand(actor) + [resolver.convert(individual), resolver.convert(institution_first), resolver.convert(institution_last), resolver.convert(world_institution)]) }
        end
      end
    end
  end
end
