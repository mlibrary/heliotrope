# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorAgentResolver do
  subject { described_class.new.expand(actor) }

  let(:resolver) { Checkpoint::Agent::Resolver.new }
  let(:actor) { double('actor', agent_type: 'actor_type', agent_id: 'actor_id', individual: individual, institutions: institutions) }
  let(:individual) { }
  let(:institutions) { [] }

  it { is_expected.to eq(resolver.expand(actor)) }

  context 'individual' do
    let(:individual) { double('individual', agent_type: 'individual_type', agent_id: 'individual_id') }

    it { is_expected.to eq(resolver.expand(actor) + [resolver.convert(individual)]) }

    context 'institutions' do
      let(:institutions) { [institution_first, institution_last] }
      let(:institution_first) { double('institution_first', agent_type: 'institution_type', agent_id: 'institution_first') }
      let(:institution_last) { double('institution_last', agent_type: 'institution_type', agent_id: 'institution_last') }

      it { is_expected.to eq(resolver.expand(actor) + [resolver.convert(individual), resolver.convert(institution_first), resolver.convert(institution_last)]) }
    end
  end
end
