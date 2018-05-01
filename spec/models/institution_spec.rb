# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Institution, type: :model do
  subject { institution }

  let(:institution) { described_class.new(identifier: identifier, name: name, site: site, login: login) }
  let(:identifier) { double('identifier') }
  let(:name) { double('name') }
  let(:site) { double('site') }
  let(:login) { double('login') }
  let(:lessee) { double('lessee') }

  before { allow(Lessee).to receive(:find_by).with(identifier: identifier.to_s).and_return(lessee) }

  it { is_expected.to be_valid }

  describe '#lessee' do
    it { expect(subject.lessee).to be lessee }
  end
end
