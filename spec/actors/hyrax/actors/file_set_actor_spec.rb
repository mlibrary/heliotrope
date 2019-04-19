# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hyrax::Actors::FileSetActor do
  let(:user)          { create(:user) }
  let(:file_set)      { create(:file_set) }
  let(:actor)         { described_class.new(file_set, user) }

  describe '#create_metadata' do
    before do
      actor.create_metadata
    end

    # https://tools.lib.umich.edu/jira/browse/HELIO-2196
    it 'does not set creator to [user.user_key] where user is depositor' do
      expect(file_set.creator).to be_empty
      expect(file_set.depositor).not_to be_blank
      expect(file_set.creator.first).not_to eq(file_set.depositor)
    end
  end
end
