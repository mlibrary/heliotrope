# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Sighrax::NullPublisher, type: :model do
  subject { Sighrax::Publisher.null_publisher(subdomain) }

  let (:subdomain) { 'valid_subdomain' }

  context 'when subdomain is blank' do
    let(:subdomain) { nil }

    it { is_expected                    .to be_an_instance_of(Sighrax::NullPublisher) }
    it { expect(subject.subdomain)      .to eq 'null_subdomain' }
    it { expect(subject.resource_id)    .to eq 'null_subdomain' }
    it { expect(subject.resource_token) .to eq 'NullPublisher:null_subdomain' }
    it { expect(subject.resource_type)  .to eq :NullPublisher }
    it { expect(subject.valid?)         .to be false }
  end

  context 'when subdomain is present' do
    it { is_expected                    .to be_an_instance_of(Sighrax::NullPublisher) }
    it { expect(subject.subdomain)      .to be subdomain }
    it { expect(subject.resource_id)    .to be subdomain }
    it { expect(subject.resource_token) .to eq "NullPublisher:#{subdomain}" }
    it { expect(subject.resource_type)  .to eq :NullPublisher }
    it { expect(subject.valid?)         .to be false }
  end
end
