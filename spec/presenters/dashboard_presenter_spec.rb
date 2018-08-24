# frozen_string_literal: true

require 'rails_helper'

describe DashboardPresenter do
  let(:current_user) { double("current_user") }

  context 'heredity' do
    it { expect(described_class.new(nil)).to be_a ApplicationPresenter }
  end

  describe '#initialize' do
    subject { described_class.new(current_user) }

    it { expect(subject.current_user).to eq current_user }
  end
end
