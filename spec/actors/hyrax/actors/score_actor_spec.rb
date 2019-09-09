# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work Score`
require 'rails_helper'

describe Hyrax::Actors::ScoreActor do
  it_behaves_like "a group permission actor for works" do
    let(:user) { create(:platform_admin) }
    let(:curation_concern) { build(:score, user: user) }
  end
end
