# frozen_string_literal: true

# https://tools.lib.umich.edu/jira/browse/HELIO-2196
Hyrax::Actors::FileSetOrderedMembersActor.class_eval do
  prepend(HeliotropeFileSetOrderedMembersActorOverrides = Module.new do
    # source: https://github.com/samvera/hyrax/blob/fdaa8bc7bf45cfa1107296a4def908b63eff1a97/app/actors/hyrax/actors/file_set_ordered_members_actor.rb
    # this is being overridden to prevent non-images from becoming the Monograph cover/thumbnail/representative,...
    # which is becoming harder to control with concurrent AttachImportFilesToWorkJobs running.

    # Adds representative and thumbnail to work; sets file_set visibility
    # @param [ActiveFedora::Base] work the parent work
    # @param [Hash] file_set_params
    def attach_to_work(work, file_set_params = {})
      file_set.visibility = work.visibility unless assign_visibility?(file_set_params)
      # heliotrope change: don't assign representative_id and thumbnail_id
      # work.representative = file_set if work.representative_id.blank?
      # work.thumbnail = file_set if work.thumbnail_id.blank?
    end
  end)
end
