# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EBookIntervalPresenter do
  describe 'attributes' do
    subject(:presenter) do
      described_class.new({
        title: title,
        level: level,
        cfi: cfi,
        downloadable?: downloadable? })
    end
    let(:title) { "A" }
    let(:level) { 1 }
    let(:cfi) { "/6/4 Title" }
    let(:downloadable?) { true }

    it '#title' do expect(presenter.title).to be title; end
    it '#level' do expect(presenter.level).to be level; end
    it '#cfi' do expect(presenter.cfi).to be cfi; end
    it '#downloadable?' do expect(presenter.downloadable?).to be downloadable?; end
  end
end
