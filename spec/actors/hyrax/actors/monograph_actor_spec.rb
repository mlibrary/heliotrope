# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
require 'rails_helper'

describe Hyrax::Actors::MonographActor do
  it_behaves_like "a group permission actor for works" do
    let(:user) { create(:platform_admin) }
    let(:curation_concern) { build(:monograph, user: user) }
  end
end
