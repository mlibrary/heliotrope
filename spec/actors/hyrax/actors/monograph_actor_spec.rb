# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
require 'rails_helper'

describe Hyrax::Actors::MonographActor do
  it_behaves_like "a group permission actor for works" do
    let(:user) { create(:platform_admin) }
    let(:curation_concern) { build(:monograph, user: user) }
  end

  context "when changing a press" do
    let(:user) { create(:platform_admin) }
    let(:press) { create(:press, subdomain: "first") }
    let(:curation_concern) do
      create(:monograph, user: user,
                         press: press.subdomain,
                         edit_groups: ["first_admin", "first_editor"],
                         read_groups: ["first_admin", "first_editor"])
    end

    subject(:middleware) do
      stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
        middleware.use described_class
      end
      stack.build(terminator)
    end

    let(:ability) { ::Ability.new(user) }
    let(:terminator) { Hyrax::Actors::Terminator.new }
    let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }

    let(:attributes) do
      {
        press: "second", # update to a new press but...
        edit_groups: ["first_admin", "first_editor"], # still has former press groups
        read_groups: ["first_admin", "first_editor"],
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      }
    end

    before do
      stub_out_redis
    end

    it "does not save the old press roles" do
      expect(curation_concern.read_groups).to match_array ["first_admin", "first_editor"]
      expect(curation_concern.edit_groups).to match_array ["first_admin", "first_editor"]

      expect(middleware.update(env)).to be true

      expect(curation_concern.press).to eq "second"
      expect(curation_concern.read_groups).to match_array ["second_admin", "second_editor", "public"]
      expect(curation_concern.edit_groups).to match_array ["second_admin", "second_editor"]
    end
  end
end
