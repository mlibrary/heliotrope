# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FakeAuthHeader do
  subject { fake_auth_header }

  let(:fake_auth_header) { described_class.new(app) }
  let(:app) { double('app') }

  describe '#call' do
    subject { fake_auth_header.call(env) }

    let(:env) { double('env') }
    let(:remote_user) { double('remote user') }

    before do
      allow(ENV).to receive(:[]).with("FAKE_HTTP_X_REMOTE_USER").and_return(remote_user)
      allow(env).to receive(:[]=).with("HTTP_X_REMOTE_USER", remote_user)
      allow(app).to receive(:call).with(env)
    end

    it { is_expected.to be nil }
  end
end
