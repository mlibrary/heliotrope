# frozen_string_literal: true

module Import
  class MonographBuilder
    attr_reader :user, :attributes
    delegate :curation_concern, to: :actor_environment

    def initialize(user, attrs)
      @attributes = attrs
      @user = user
    end

    def run
      actor.create(actor_environment)
    end

    private

      def actor
        @actor ||= Hyrax::CurationConcern.actor
      end

      def actor_environment
        @actor_environment ||= Hyrax::Actors::Environment.new(Monograph.new, Ability.new(user), attributes)
      end
  end
end
