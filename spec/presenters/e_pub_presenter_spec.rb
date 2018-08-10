# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPresenter do
  subject { presenter }

  let(:presenter) { described_class.new(epub) }
  let(:epub) { double('epub', sections: sections) }
  let(:sections) { [section] }
  let(:section) { double('section') }

  describe '#sections' do
    subject { presenter.sections.first }

    it { is_expected.to be_an_instance_of(EPubSectionPresenter) }
  end
end
