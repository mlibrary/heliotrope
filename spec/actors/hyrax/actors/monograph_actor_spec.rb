# frozen_string_literal: true

# Generated via
#  `rails generate curation_concerns:work Monograph`
require 'rails_helper'

describe Hyrax::Actors::MonographActor do
  subject { Hyrax::CurationConcern.actor(monograph, ::Ability.new(user)) }

  let(:user) { create(:user) }
  let(:monograph) { Monograph.new }
  let(:admin_set) { create(:admin_set, with_permission_template: { with_active_workflow: true }) }

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
        subject.create(attributes)

        expect(monograph.read_groups).to eq ["heliotrope_admin", "heliotrope_editor"]
        expect(monograph.edit_groups).to eq ["heliotrope_admin", "heliotrope_editor"]
      end
    end
  end
end
