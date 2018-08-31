# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubPresenter do
  subject { presenter }

  let(:presenter) { described_class.new(epub) }
  let(:epub) { double('epub', rendition: rendition, multi_rendition?: true) }
  let(:rendition) { double('rendition', intervals: intervals) }
  let(:intervals) { [interval] }
  let(:interval) { double('interval') }

  describe '#intervals' do
    subject { presenter.intervals.first }

    it { is_expected.to be_an_instance_of(EPubIntervalPresenter) }
  end

  describe '#multi_rendition' do
    it { expect(subject.multi_rendition?).to be true }
  end
end
