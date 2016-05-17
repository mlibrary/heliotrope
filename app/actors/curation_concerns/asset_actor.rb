module CurationConcerns
  class AssetActor < CurationConcerns::FileSetActor
    # Adds the appropriate metadata, visibility and relationships to file_set
    #
    # *Note*: In past versions of Sufia this method did not perform a save because it is mainly used in conjunction with
    # create_content, which also performs a save.  However, due to the relationship between Hydra::PCDM objects,
    # we have to save both the parent work and the file_set in order to record the "metadata" relationship
    # between them.
    # @param [ActiveFedora::Base] work the parent work that will contain the file_set.
    # @param [Hash] file_set specifying the visibility, lease and/or embargo of the file set.  If you don't provide at least one of visibility, embargo_release_date or lease_expiration_date, visibility will be copied from the parent.

    def create_metadata(work, file_set_params = {})
      file_set.apply_depositor_metadata(user)
      now = CurationConcerns::TimeService.time_in_utc
      file_set.date_uploaded = now
      file_set.date_modified = now
      # file_set.creator = [user.user_key]
      # See story #188. Curation Concerns defaults to user.user_key, we don't want that.
      # This is the only local change to #create_metadata, the rest is from CC
      file_set.creator = file_set_params['creator'] || [user.user_key]

      ActorStack.new(file_set, user, [InterpretVisibilityActor]).create(file_set_params) if assign_visibility?(file_set_params)
      attach_file_to_work(work, file_set, file_set_params) if work
      yield(file_set) if block_given?
    end
  end
end
