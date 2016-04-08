module Import
  class MonographBuilder
    attr_reader :user, :attributes
    delegate :curation_concern, to: :actor

    def initialize(user, attrs)
      @attributes = attrs
      @user = user
    end

    def run
      actor.create
    end

    private

      def actor
        @actor ||= CurationConcerns::CurationConcern.actor(Monograph.new, user, attributes)
      end
  end
end
