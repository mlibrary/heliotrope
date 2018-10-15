# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActorAgentResolver do
  subject { described_class.new.resolve(actor) }

  let(:actor) { { email: email, institutions: institutions } }
  let(:email) { nil }
  let(:institutions) { nil }
  let(:any_actor) { Checkpoint::Agent.from(OpenStruct.new(agent_type: :any, agent_id: :any)) }

  it { is_expected.to be_an(Array) }
  it { is_expected.to eq([any_actor]) }

  context 'email' do
    let(:email) { 'user@example.com' }
    let(:email_agent) { Checkpoint::Agent.from(OpenStruct.new(agent_type: :email, agent_id: email)) }

    it { is_expected.to eq([any_actor, email_agent]) }
  end

  context 'institutions' do
    let(:institutions) { [institution_first, institution_last] }
    let(:institution_first) { double('institution_first', identifier: 'first') }
    let(:institution_last) { double('institution_last', identifier: 'last') }
    let(:institution_first_agent) { Checkpoint::Agent.from(OpenStruct.new(agent_type: :institution, agent_id: institution_first.identifier)) }
    let(:institution_last_agent) { Checkpoint::Agent.from(OpenStruct.new(agent_type: :institution, agent_id: institution_last.identifier)) }

    it { is_expected.to eq([any_actor, institution_first_agent, institution_last_agent]) }
  end
end
