# frozen_string_literal: true

require 'rails_helper'

describe PressStatisticsPresenter do
  subject(:presenter) { described_class.new(press) }

  let(:press) { Press.new(subdomain: 'zzz') }

  it do
    expect(subject.subdomain).to eq 'zzz'
    expect(subject.subdomain).to eq press.subdomain
  end
end
