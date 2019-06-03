# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EPubIntervalPresenter do
  describe 'attributes' do
    subject(:presenter) { described_class.new(interval) }

    let(:interval) { instance_double(EPub::Interval, 'interval', title: title, level: level, cfi: cfi, downloadable?: downloadable) }
    let(:title) { double('title') }
    let(:level) { double('level') }
    let(:cfi) { double('cfi') }
    let(:downloadable) { double('downloadable') }

    it '#title' do; expect(presenter.title).to be title; end
    it '#level' do; expect(presenter.level).to be level; end
    it '#cfi' do; expect(presenter.cfi).to be cfi; end
    it '#downloadable?' do; expect(presenter.downloadable?).to be downloadable; end
  end
end
