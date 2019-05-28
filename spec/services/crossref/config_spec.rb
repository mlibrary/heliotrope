# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Crossref::Config do
  describe "#load_config" do
    subject { described_class.load_config }

    context "with a config" do
      let(:config_file) { Rails.root.join('config', 'crossref.yml.sample') }

      before { allow(Rails.root).to receive(:join).and_return(config_file) }

      it "has the correct fields" do
        expect(subject['deposit_url']).not_to be nil
        expect(subject['check_url']).not_to be nil
        expect(subject['search_url']).not_to be nil
        expect(subject['login_id']).not_to be nil
        expect(subject['login_passwd']).not_to be nil
      end
    end

    context "with no config" do
      before do
        allow(Rails.root).to receive(:join).and_return("")
        allow(Rails.logger).to receive(:error).and_return(true)
      end

      it "has no fields" do
        expect(subject.blank?).to be true
      end
    end
  end
end
