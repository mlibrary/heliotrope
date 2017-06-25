# frozen_string_literal: true

module Import
  class MonographBuilder
    attr_reader :user, :attributes
    delegate :curation_concern, to: :actor

    def initialize(user, attrs)
      @attributes = attrs
      @user = user
    end

    def run
      actor.create(attributes)
    end

    private

      def actor
        # @actor ||= Hyrax::CurationConcern.actor(Monograph.new, Ability.new(user))
        @actor ||= Hyrax::CurationConcern.actor
      end
  end
end
