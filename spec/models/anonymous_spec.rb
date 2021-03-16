# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Anonymous, type: :model do
  subject { described_class.new(request_attributes) }

  let(:request_attributes) { {} }

  it { expect(subject.email).to be nil }
  it { expect(subject.individual).to be nil }
  it { expect(subject.institutions).to eq [] }
  it { expect(subject.agent_type).to eq :Anonymous }
  it { expect(subject.agent_id).to eq :any }
  it { expect(subject.platform_admin?).to be false }
  it { expect(subject.developer?).to be false }
  it { expect(subject.admin_presses).to be_empty }
  it { expect(subject.editor_presses).to be_empty }
  it { expect(subject.analyst_presses).to be_empty }
end
