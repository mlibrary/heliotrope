# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorAgentResolver do
  subject { described_class.new.resolve(actor) }

  let(:actor) { { user: current_user, institutions: current_institutions } }
  let(:current_user) { nil }
  let(:current_institutions) { nil }
  let(:any_actor) { Checkpoint::Agent.from(OpenStruct.new(agent_type: :any, agent_id: :any)) }

  let(:user) { User.new(email: user_email) }
  let(:user_email) { 'user@umich.edu' }
  let(:user_agent) { Checkpoint::Agent.from(user) }
  let(:individual) { Individual.new(email: individual_email) }
  let(:individual_email) { 'individual@umich.edu' }
  let(:individual_agent) { Checkpoint::Agent.from(individual) }
  let(:institution_first) { Institution.new(identifier: 'first') }
  let(:institution_first_agent) { Checkpoint::Agent.from(institution_first) }
  let(:institution_last) { Institution.new(identifier: 'last') }
  let(:institution_last_agent) { Checkpoint::Agent.from(institution_last) }

  before do
    allow(User).to receive(:find_by).with(email: anything)
    allow(User).to receive(:find_by).with(email: user.email).and_return(user)
    allow(Individual).to receive(:find_by).with(email: anything)
    allow(Individual).to receive(:find_by).with(email: individual.email).and_return(individual)
  end

  it { is_expected.to be_an(Array) }
  it { is_expected.to eq([any_actor]) }

  context 'current user' do
    let(:current_user) { User.new(email: current_email) }
    let(:current_email) { 'wolverine@umich.edu' }

    it { is_expected.to eq([any_actor]) }

    context 'user' do
      let(:user_email) { current_email }

      it { is_expected.to eq([any_actor, user_agent]) }

      context 'individual' do
        let(:individual_email) { current_email }

        it { is_expected.to eq([any_actor, user_agent, individual_agent]) }

        context 'institutions' do
          let(:current_institutions) { [institution_first, institution_last] }

          it { is_expected.to eq([any_actor, user_agent, individual_agent, institution_first_agent, institution_last_agent]) }
        end
      end

      context 'institutions' do
        let(:current_institutions) { [institution_first, institution_last] }

        it { is_expected.to eq([any_actor, user_agent, institution_first_agent, institution_last_agent]) }
      end
    end

    context 'individual' do
      let(:individual_email) { current_email }

      it { is_expected.to eq([any_actor, individual_agent]) }

      context 'institutions' do
        let(:current_institutions) { [institution_first, institution_last] }

        it { is_expected.to eq([any_actor, individual_agent, institution_first_agent, institution_last_agent]) }
      end
    end

    context 'institutions' do
      let(:current_institutions) { [institution_first, institution_last] }

      it { is_expected.to eq([any_actor, institution_first_agent, institution_last_agent]) }
    end
  end

  context 'institutions' do
    let(:current_institutions) { [institution_first, institution_last] }

    it { is_expected.to eq([any_actor, institution_first_agent, institution_last_agent]) }
  end
end
