# frozen_string_literal: true

require 'rails_helper'

describe ManifestPresenter do
  subject(:presenter) { described_class.new(current_user, manifest) }

  let(:current_user) { double("current_user") }
  let(:manifest) { double("manifest", id: "manifest") }

  it do
    expect(subject.current_user).to be current_user
    expect(subject.id).to eq manifest.id
  end
end
