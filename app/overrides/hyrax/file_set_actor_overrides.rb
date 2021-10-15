# frozen_string_literal: true

# https://tools.lib.umich.edu/jira/browse/HELIO-2196
Hyrax::Actors::FileSetActor.class_eval do # rubocop:disable Metrics/BlockLength
  prepend(HeliotropeFileSetActorOverrides = Module.new do
    # source: https://github.com/samvera/hyrax/blob/4ae385ba69d189ba4d9cf4c279d0a58368d3be67/app/actors/hyrax/actors/file_set_actor.rb
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

    # Spawns asynchronous IngestJob with user notification afterward
    # @param [Hyrax::UploadedFile, File, ActionDigest::HTTP::UploadedFile] file the file uploaded by the user
    # @param [Symbol, #to_s] relation
    # @return [IngestJob] the queued job
    def update_content(file, relation = :original_file)
      # HELIO-3506 override for tempfiles uploaded via Versioning
      if file.is_a?(Hyrax::UploadedFile)
        IngestJob.perform_later(wrapper!(file: file, relation: relation), notification: true)
      else
        IngestJob.perform_now(wrapper!(file: file, relation: relation), notification: true)
      end
    end


    # Adds a FileSet to the work using ore:Aggregations.
    # Locks to ensure that only one process is operating on the list at a time.
    def attach_to_work(work, file_set_params = {})
      acquire_lock_for(work.id) do
        # Ensure we have an up-to-date copy of the members association, so that we append to the end of the list.
        work.reload unless work.new_record?
        file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
        work.ordered_members << file_set
        # heliotrope change: don't assign representative_id and thumbnail_id
        # work.representative = file_set if work.representative_id.blank?
        # work.thumbnail = file_set if work.thumbnail_id.blank?
        # Save the work so the association between the work and the file_set is persisted (head_id)
        # NOTE: the work may not be valid, in which case this save doesn't do anything.
        work.save
        Hyrax.config.callback.run(:after_create_fileset, file_set, user)
      end
    end
    alias attach_file_to_work attach_to_work # rubocop:disable Style/Alias
    deprecation_deprecate attach_file_to_work: "use attach_to_work instead"
  end)
end
