# frozen_string_literal: true

module Import
  class MonographBuilder
    attr_reader :user, :attributes, :curation_concern

    def initialize(user, attrs)
      @attributes = attrs
      @user = user
      @curation_concern = nil
    end

    def run
      @curation_concern = Monograph.new
      actor.create(Hyrax::Actors::Environment.new(curation_concern, Ability.new(user), attributes))
    end

    private

      def actor
        @actor ||= Hyrax::CurationConcern.actor
      end
  end
end
