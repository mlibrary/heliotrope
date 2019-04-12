# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Presenter do
  context 'null presenter' do
    subject { described_class.null_presenter }

    it { is_expected.to be_an_instance_of(Hyrax::NullPresenter) }
  end

  context 'presenter' do
    subject(:presenter) { described_class.send(:new, noid) }

    let(:noid) { 'validnoid' }

    it { is_expected.to be_an_instance_of(described_class) }
  end
end
