# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
require 'rails_helper'

describe Hyrax::Actors::MonographActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:curation_concern) { build(:monograph, user: user) }
  let(:ability) { ::Ability.new(user) }
  let(:user) { create(:platform_admin) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:env) { Hyrax::Actors::Environment.new(curation_concern, ability, attributes) }

  describe "create" do
    before do
      stub_out_redis
    end

    context "with a non-public visibility" do
      let(:attributes) do
        { title: ["Things About Stuff"],
          press: "heliotrope",
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      end

      it "adds default group read and edit permissions" do
        expect(middleware.create(env)).to be true

        expect(curation_concern.read_groups).to match_array ["heliotrope_admin", "heliotrope_editor"]
        expect(curation_concern.edit_groups).to match_array ["heliotrope_admin", "heliotrope_editor"]
      end

      it "updates to public" do
        attributes["visibility"] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(middleware.create(env)).to be true

        expect(curation_concern.read_groups).to include("public")
      end
    end

    context "with a public visibility" do
      let(:attributes) do
        { title: ["Things About Stuff"],
          press: "heliotrope",
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      end

      it "adds default group read and edit permissions including public read" do
        expect(middleware.create(env)).to be true

        expect(curation_concern.read_groups).to match_array ["heliotrope_admin", "heliotrope_editor", "public"]
        expect(curation_concern.edit_groups).to match_array ["heliotrope_admin", "heliotrope_editor"]
      end

      it "updates with a new group" do
        (attributes["edit_groups"] ||= []).push("anotherpress_editor")
        expect(middleware.update(env)).to be true

        expect(curation_concern.edit_groups).to match_array ["heliotrope_admin", "heliotrope_editor", "anotherpress_editor"]
      end

      it "updates to private" do
        attributes["visibility"] = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(middleware.update(env)).to be true

        expect(curation_concern.read_groups).to_not include("public")
      end
    end
  end
end
