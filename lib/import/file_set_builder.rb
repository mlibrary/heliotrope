module Import
  class FileSetBuilder
    attr_reader :file_set, :user, :attributes

    def initialize(file_set, user, attributes)
      @file_set = file_set
      @user = user
      @attributes = attributes
    end

    def run
      actor.update_metadata(attributes)
      # TODO: Check the return value of update_metadata method:
      # success = actor.update_metadata(attributes)
      # if not successful raise an error
    end

    private

      def actor
        @actor ||= CurationConcerns::FileSetActor.new(file_set, user)
      end
  end
end
