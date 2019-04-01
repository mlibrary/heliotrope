# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Fighrax::FedoraContain, type: :model do
  subject { described_class.new(id: id, uri: uri, noid: noid, model: model, title: title) }

  let(:id) { 1 }
  let(:uri) { double('uri') }
  let(:noid) { double('noid') }
  let(:model) { double('model') }
  let(:title) { double('title') }

  it { is_expected.to be an_instance_of(described_class) }
end
