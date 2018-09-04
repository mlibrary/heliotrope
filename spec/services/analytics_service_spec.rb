# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AnalyticsService, :no_clean do
  before do
    described_class.send(:remove_instance_variable, :@config) if described_class.send(:instance_variable_defined?, :@config)
  end

  describe "configuration" do
    let(:config) { described_class.send(:config) }

    context "When the yaml file has values" do
      before do
        allow(File).to receive(:exist?).and_return true
        allow(File).to receive(:read).and_return("# Loads configuration options from config/analytics.yml. Expected structure:\nanalytics:\n  app_name: 'My App Name'\n  app_version: '0.0.1'\n  privkey_path: '/tmp/privkey.p12'\n  privkey_secret: 's00pers3kr1t'\n  client_email: 'oauth@example.org'\n")
      end

      it "is valid" do
        expect(config).to be_valid
      end

      it 'reads its config from a yaml file' do
        expect(config.app_name).to eql 'My App Name'
        expect(config.app_version).to eql '0.0.1'
        expect(config.privkey_path).to eql '/tmp/privkey.p12'
        expect(config.privkey_secret).to eql 's00pers3kr1t'
        expect(config.client_email).to eql 'oauth@example.org'
      end
    end

    context "When the yaml file has no values" do
      before do
        allow(File).to receive(:exist?).and_return true
        allow(File).to receive(:read).and_return("# Just comments\n# and comments\n")
      end

      it "is not valid" do
        expect(Rails.logger).to receive(:error)
          .with(starting_with("Unable to fetch any keys from"))
        expect(config).not_to be_valid
      end
    end
  end

  describe "#user" do
    before do
      token = OAuth2::AccessToken.new(nil, nil)
      allow(subject).to receive(:token).and_return(token)
    end

    it 'instantiates a user' do
      expect(subject.send(:user)).to be_a(Legato::User)
    end
  end

  describe "#profile" do
    subject { described_class.profile('required_ga_id') }

    context "when the private key file is missing" do
      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when the config is not valid" do
      before do
        allow(File).to receive(:read).and_return("# Just comments\n# and comments\n")
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end
end
