module Import
  class SectionBuilder
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
        @actor ||= CurationConcerns::CurationConcern.actor(Section.new, user)
      end
  end
end
