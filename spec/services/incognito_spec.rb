# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Incognito do
  subject(:incognito) { described_class }

  let(:actor) { create(:user) }
  let(:admin) { false }
  let(:individual) { create(:individual, identifier: actor.email) }
  let(:institutions) { [create(:institution), create(:institution)] }

  before do
    allow(actor).to receive(:platform_admin?).and_return(admin)
    allow(actor).to receive(:individual).and_return(individual)
    allow(actor).to receive(:institutions).and_return(institutions)
  end

  it do
    expect(incognito.allow_all(actor)).to be true
    expect(incognito.allow_platform_admin?(actor)).to be true

    expect(incognito.allow_platform_admin(actor, false)).to be true
    expect(incognito.allow_platform_admin?(actor)).to be true

    expect(incognito.allow_hyrax_can?(actor)).to be true
    expect(incognito.allow_hyrax_can(actor, false)).to be true
    expect(incognito.allow_hyrax_can?(actor)).to be true

    expect(incognito.allow_action_permitted?(actor)).to be true
    expect(incognito.allow_action_permitted(actor, false)).to be true
    expect(incognito.allow_action_permitted?(actor)).to be true
  end

  context 'platform_admin' do
    let(:admin) { true }

    it do
      expect(incognito.allow_all(actor)).to be true
      expect(incognito.allow_platform_admin?(actor)).to be true

      expect(incognito.allow_platform_admin(actor, false)).to be false
      expect(incognito.allow_platform_admin?(actor)).to be false

      expect(incognito.allow_platform_admin(actor)).to be true
      expect(incognito.allow_platform_admin?(actor)).to be true

      expect(incognito.allow_hyrax_can?(actor)).to be true
      expect(incognito.allow_hyrax_can(actor, false)).to be false
      expect(incognito.allow_hyrax_can?(actor)).to be false

      expect(incognito.allow_hyrax_can(actor)).to be true
      expect(incognito.allow_hyrax_can?(actor)).to be true

      expect(incognito.allow_action_permitted?(actor)).to be true
      expect(incognito.allow_action_permitted(actor, false)).to be false
      expect(incognito.allow_action_permitted?(actor)).to be false

      expect(incognito.allow_action_permitted(actor)).to be true
      expect(incognito.allow_action_permitted?(actor)).to be true
    end
  end
end
