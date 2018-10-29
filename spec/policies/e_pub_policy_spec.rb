# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPolicy do
  subject { described_class.new(current_user, current_institutions, e_pub_id).authorize!(action) }

  let(:current_user) { double('current_user', email: nil) }
  let(:current_institutions) { nil }
  let(:e_pub_id) { nil }
  let(:action) { :action }
  let(:checkpoint) { double('checkpoint') }
  let(:permits) { false }

  before do
    allow(Services).to receive(:checkpoint).and_return(checkpoint)
    allow(checkpoint).to receive(:permits?).with({ user: current_user, institutions: current_institutions }, action, noid: e_pub_id).and_return(permits)
  end

  it ':action denied' do expect { subject }.to raise_error(NotAuthorizedError) end

  context 'permitted' do
    let(:permits) { true }

    it ':action permitted' do expect { subject }.not_to raise_error(NotAuthorizedError) end
  end
end
