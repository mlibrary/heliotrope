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
end
