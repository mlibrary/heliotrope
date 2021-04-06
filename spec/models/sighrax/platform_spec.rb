# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::Platform, type: :model do
  let(:platform) { described_class.send(:new) }

  describe '#tombstone_message' do
    subject { platform.tombstone_message('publisher') }

    it { is_expected.to eq I18n.t('sighrax.platform.tombstone_message', publisher: 'publisher') }
  end
end
