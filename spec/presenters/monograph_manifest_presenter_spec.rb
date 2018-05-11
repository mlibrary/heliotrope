# frozen_string_literal: true

require 'rails_helper'

describe MonographManifestPresenter do
  subject(:presenter) { described_class.new(current_user, monograph_manifest) }

  let(:current_user) { double("current_user") }
  let(:monograph_manifest) { double("monograph_manifest", id: "manifest", explicit: explicit, implicit: implicit) }
  let(:explicit) { double("explicit", id: "explicit") }
  let(:implicit) { double("implicit", id: "implicit") }

  it do
    expect(subject.current_user).to be current_user
    expect(subject.id).to eq monograph_manifest.id
    expect(subject.explicit).to be_a(ManifestPresenter)
    expect(subject.explicit.id).to eq explicit.id
    expect(subject.implicit).to be_a(ManifestPresenter)
    expect(subject.implicit.id).to eq implicit.id
    expect(subject.equivalent?).to be false
  end
end
