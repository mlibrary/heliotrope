# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Anonymous, type: :model do
  subject { described_class.new(request_attributes) }

  let(:request_attributes) { {} }
  let(:institution) { build(:institution, id: 100) }
  let(:affiliation) { build(:institution_affiliation, institution_id: 100) }

  it { is_expected.to be_a Actorable }
  it { expect(subject.email).to be nil }
  it { expect(subject.individual).to be nil }
  it { expect(subject.institutions).to eq [] }
  it { expect(subject.affiliations(institution)).to eq [] }
  it { expect(subject.agent_type).to eq :Anonymous }
  it { expect(subject.agent_id).to eq :any }
  it { expect(subject.platform_admin?).to be false }
  it { expect(subject.developer?).to be false }
  it { expect(subject.presses).to be_empty }
  it { expect(subject.admin_presses).to be_empty }
  it { expect(subject.editor_presses).to be_empty }
  it { expect(subject.analyst_presses).to be_empty }

  context 'when institution' do
    before { allow(Services.dlps_institution).to receive(:find).with(request_attributes).and_return [institution] }

    it { expect(subject.institutions).to contain_exactly(institution) }
  end

  context 'when affiliations' do
    before { allow(Services.dlps_institution_affiliation).to receive(:find).with(request_attributes).and_return [affiliation] }

    it { expect(subject.affiliations(institution)).to contain_exactly(affiliation) }
    it { expect(subject.affiliations(build(:institution, id: 101))).to eq [] }
  end
end
