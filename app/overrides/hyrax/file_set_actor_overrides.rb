# frozen_string_literal: true

# https://tools.lib.umich.edu/jira/browse/HELIO-2196
Hyrax::Actors::FileSetActor.class_eval do
  prepend(HeliotropeFileSetActorOverrides = Module.new do
    # source: https://github.com/samvera/hyrax/blob/4ae385ba69d189ba4d9cf4c279d0a58368d3be67/app/actors/hyrax/actors/file_set_actor.rb#L56
    def create_metadata(file_set_params = {})
      file_set.depositor = depositor_id(user)
      now = Hyrax::TimeService.time_in_utc
      file_set.date_uploaded = now
      file_set.date_modified = now
      # Heliotrope change. Don't do this.
      # file_set.creator = [user.user_key]
      if assign_visibility?(file_set_params)
        env = Hyrax::Actors::Environment.new(file_set, ability, file_set_params)
        Hyrax::CurationConcern.file_set_create_actor.create(env)
      end
      yield(file_set) if block_given?
    end
  end)
end
