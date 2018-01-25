# frozen_string_literal: true

require 'rails_helper'

describe FeaturedRepresentativeActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:ability) { nil }
  let(:monograph_env) { Hyrax::Actors::Environment.new(monograph, ability, attributes) }
  let(:file_set_env) { Hyrax::Actors::Environment.new(file_set, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:monograph) { create(:monograph) }
  let(:file_set) { create(:file_set) }
  let(:attributes) { {} }

  before do
    monograph.ordered_members << file_set
    monograph.save!
  end

  describe "#destroy" do
    context "for a monograph" do
      subject { middleware.destroy(monograph_env) }

      let!(:fr) { FeaturedRepresentative.create(monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      it 'removes the featured_representative' do
        expect { middleware.destroy(monograph_env) }.to change { FeaturedRepresentative.where(monograph_id: monograph.id).count }.from(1).to(0)
      end
    end

    context "for a file_set" do
      subject { middleware.destroy(file_set_env) }

      let!(:fr) { FeaturedRepresentative.create(monograph_id: monograph.id, file_set_id: file_set.id, kind: 'epub') }

      it 'removes the featured_representative' do
        expect { middleware.destroy(file_set_env) }.to change { FeaturedRepresentative.where(file_set_id: file_set.id).count }.from(1).to(0)
      end
    end
  end
end
