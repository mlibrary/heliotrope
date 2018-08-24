# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPresenter do
  subject { presenter }

  let(:presenter) { described_class.new(epub) }
  let(:epub) { double('epub', sections: sections, multi_rendition?: true) }
  let(:sections) { [section] }
  let(:section) { double('section') }

  describe '#sections' do
    subject { presenter.sections.first }

    it { is_expected.to be_an_instance_of(EPubSectionPresenter) }
  end

  describe '#multi_rendition' do
    it { expect(subject.multi_rendition?).to be true }
  end
end
