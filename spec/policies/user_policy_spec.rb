# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UserPolicy do
  subject { user_policy }

  let(:user_policy) { described_class.new(current_user) }
  let(:current_user) { double('current user', id: 'user_id') }

  before { allow(current_user).to receive(:platform_admin?).and_return(false) }

  it { is_expected.to be_a_kind_of(ApplicationPolicy) }
  it { expect { subject.authorize!(:action?) }.to raise_error(NotAuthorizedError) }

  context 'platform_admin?' do
    before { allow(current_user).to receive(:platform_admin?).and_return(true) }

    it { expect { subject.authorize!(:action?) }.not_to raise_error }
  end
end
