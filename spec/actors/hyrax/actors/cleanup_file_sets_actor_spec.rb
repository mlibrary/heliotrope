# frozen_string_literal: true

require 'rails_helper'

describe Hyrax::Actors::CleanupFileSetsActor do
  subject(:middleware) do
    stack = ActionDispatch::MiddlewareStack.new.tap do |middleware|
      middleware.use described_class
    end
    stack.build(terminator)
  end

  let(:ability) { nil }
  let(:monograph_env) { Hyrax::Actors::Environment.new(monograph, ability, attributes) }
  let(:terminator) { Hyrax::Actors::Terminator.new }
  let(:monograph) { create(:monograph) }
  let(:file_set1) { create(:file_set) }
  let(:file_set2) { create(:file_set) }
  let(:file_set3) { create(:file_set) }
  let(:attributes) { {} }

  before do
    monograph.ordered_members << file_set1 << file_set2 << file_set3
    monograph.save!
  end

  describe "#destroy" do
    context "for a monograph" do
      subject { middleware.destroy(monograph_env) }

      it 'removes the Monograph, FileSets and ListSource' do
        expect { middleware.destroy(monograph_env) }
          .to change(Monograph, :count)
          .by(-1)
          .and(change(FileSet, :count)
          .by(-3))
          .and(change(ActiveFedora::Aggregation::ListSource, :count)
          .by(-1))
      end
    end
  end
end
