# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject { described_class.new(current_user, current_institutions, e_pub_id).authorize!(action) }

  let(:current_user) { double('current_user', email: '') }
  let(:current_institutions) { [] }
  let(:e_pub_id) { 'validnoid' }
  let(:action) { :action }

  it ':action denied' do expect { subject }.to raise_error(NotAuthorizedError) end

  describe ':show' do
    let(:action) { :show }

    it 'granted' do expect { subject }.not_to raise_error end

    context 'component' do
      let(:component) { double('component') }
      let(:actor) { { email: current_user.email, institutions: current_institutions } }
      let(:authority) { double('authority') }
      let(:actor_agent_resolver) { double('actor_agent_resolver') }
      let(:component_resource_resolver) { double('component_resource_resolver') }
      let(:query) { double('query', true?: false) }

      before do
        allow(Component).to receive(:find_by).with(handle: HandleService.path(e_pub_id)).and_return(component)
        allow(Checkpoint::Authority).to receive(:new).with(agent_resolver: actor_agent_resolver, resource_resolver: component_resource_resolver).and_return(authority)
        allow(ActorAgentResolver).to receive(:new).and_return(actor_agent_resolver)
        allow(ComponentResourceResolver).to receive(:new).and_return(component_resource_resolver)
        allow(Checkpoint::Query::ActionPermitted).to receive(:new).with(actor, action, component, authority: authority).and_return(query)
      end

      it 'not permitted' do expect { subject }.to raise_error(NotAuthorizedError) end

      context 'query' do
        let(:query) { double('query', true?: true) }

        it 'permitted' do expect { subject }.not_to raise_error end
      end
    end
  end
end
