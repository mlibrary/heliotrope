# frozen_string_literal: true

module Import
  class MonographBuilder
    attr_reader :user, :attributes, :curation_concern

    def initialize(user, attrs)
      @attributes = attrs
      @user = user
      if user.id.zero?
        @user = User.where("email = 'system@example.com'").first
        if @user.blank?
          @user = User.create!(email: 'system@example.com', password: 'system@example.com')
        end
      end
      @curation_concern = nil
    end

    def run
      @curation_concern = Monograph.new
      # CreateWithFilesActor
      files = attributes.delete('files')
      uploaded_files = []
      files.each do |file|
        uploaded_file = Hyrax::UploadedFile.create(user: user, file: file)
        uploaded_file.save!
        uploaded_files << uploaded_file.id
      end
      attributes['uploaded_files'] = uploaded_files
      actor.create(Hyrax::Actors::Environment.new(curation_concern, Ability.new(user), attributes))
    end

    private

      def actor
        @actor ||= Hyrax::CurationConcern.actor
      end
  end
end
