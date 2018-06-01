# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationPolicy do
  subject { application_policy }

  let(:application_policy) { described_class.new(current_user, resource_class, resource) }
  let(:current_user) { double('current_user', id: 'user_id') }
  let(:resource_class) { double('resource class', name: 'Resource') }
  let(:resource) { double('resource', id: 'resource_id') }
  let(:message) { 'message' }

  before { allow(current_user).to receive(:platform_admin?).and_return(false) }

  it { expect(subject.send(:authority)).to be Services.checkpoint }
  it { expect { subject.authorize!(:action) }.to raise_error(NotActionError) }
  it { expect { subject.authorize!(:action?) }.to raise_error(NotAuthorizedError) }

  context 'platform_admin?' do
    before { allow(current_user).to receive(:platform_admin?).and_return(true) }

    it { expect { subject.authorize!(:action?) }.not_to raise_error }
  end

  context 'action?' do
    before { allow(application_policy).to receive(:action?).and_return(true) }

    it { expect { subject.authorize!(:action?) }.not_to raise_error }
  end

  context 'action_permitted?' do
    before { allow(application_policy).to receive(:action_permitted?).with(:action).and_return(true) }

    it { expect { subject.authorize!(:action?) }.not_to raise_error }
  end
end
