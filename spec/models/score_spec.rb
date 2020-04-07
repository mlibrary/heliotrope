# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Score do
  subject { score }

  let(:score) { described_class.new }

  it 'includes HeliotropeUniverialMetadata' do
    is_expected.to be_a HeliotropeUniversalMetadata
  end

  context 'handles' do
    let(:score) { build(:score, id: noid) }
    let(:noid) { 'validnoid' }

    before do
      ActiveFedora::Cleaner.clean!
      allow(HandleCreateJob).to receive(:perform_later).with(noid)
      allow(HandleDeleteJob).to receive(:perform_later).with(noid)
    end

    it 'creates a handle after create and deletes the handle after destroy' do
      score.save
      expect(HandleCreateJob).to have_received(:perform_later).with(noid)
      score.destroy
      expect(HandleDeleteJob).to have_received(:perform_later).with(noid)
    end
  end
end
