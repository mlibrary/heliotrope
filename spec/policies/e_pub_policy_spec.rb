# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject { described_class.new(current_user, current_institutions, e_pub_id).authorize!(action) }

  let(:current_user) { double('current_user', email: nil) }
  let(:current_institutions) { nil }
  let(:e_pub_id) { nil }
  let(:action) { :action }

  it ':action denied' do expect { subject }.to raise_error(NotAuthorizedError) end

  context 'query' do
    let(:actor) { { email: current_user.email, institutions: current_institutions } }
    let(:target) { { noid: e_pub_id, products: component.products } }
    let(:component) { double('component', products: products) }
    let(:products) { nil }
    let(:authority) { double('authority') }
    let(:actor_agent_resolver) { double('actor_agent_resolver') }
    let(:target_resource_resolver) { double('target_resource_resolver') }
    let(:query) { double('query', true?: false) }

    before do
      allow(Component).to receive(:find_by).with(handle: HandleService.path(e_pub_id)).and_return(component)
      allow(Checkpoint::Authority).to receive(:new).with(agent_resolver: actor_agent_resolver, resource_resolver: target_resource_resolver).and_return(authority)
      allow(ActorAgentResolver).to receive(:new).and_return(actor_agent_resolver)
      allow(TargetResourceResolver).to receive(:new).and_return(target_resource_resolver)
      allow(Checkpoint::Query::ActionPermitted).to receive(:new).with(actor, action, target, authority: authority).and_return(query)
    end

    it 'not permitted' do expect { subject }.to raise_error(NotAuthorizedError) end

    context 'query' do
      let(:query) { double('query', true?: true) }

      it 'permitted' do expect { subject }.not_to raise_error end
    end
  end
end
