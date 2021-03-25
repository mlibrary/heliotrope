# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntityPolicy do
  let(:entity_policy) { described_class.new(actor, target) }
  let(:actor) { instance_double(Anonymous, 'actor') }
  let(:target) { instance_double(Sighrax::Resource, 'target') }
  let(:resource_download_op) { instance_double(ResourceDownloadOperation, 'resource_download_op', allowed?: allowed) }
  let(:allowed) { double('allowed') }

  before { allow(ResourceDownloadOperation).to receive(:new).with(actor, target).and_return resource_download_op }

  describe '#download?' do
    subject { entity_policy.download? }

    it { is_expected.to be allowed }
  end
end
