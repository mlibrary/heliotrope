# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubSectionPresenter do
  describe 'attributes' do
    subject { presenter }

    let(:presenter) { described_class.new(section) }
    let(:section) { double('section', title: title, level: level, cfi: cfi, downloadable?: downloadable) }
    let(:title) { double('title') }
    let(:level) { double('level') }
    let(:cfi) { double('cfi') }
    let(:downloadable) { double('downloadable') }

    it { expect(subject.title).to be title }
    it { expect(subject.level).to be level }
    it { expect(subject.cfi).to be cfi }
    it { expect(subject.downloadable?).to be downloadable }
  end
end
