# frozen_string_literal: true

# https://tools.lib.umich.edu/jira/browse/HELIO-2196
Hyrax::Actors::OrderedMembersActor.class_eval do
  prepend(HeliotropeOrderedMembersActorOverrides = Module.new do
    # source: https://github.com/samvera/hyrax/blob/fdaa8bc7bf45cfa1107296a4def908b63eff1a97/app/actors/hyrax/actors/ordered_members_actor.rb
    # this is being overridden to ensure that the current state of `work.ordered_members` is gleaned while the work...
    # is locked and the incoming members are appended. Otherwise jobs running concurrently will see different members.

    # Adds FileSets to the work using ore:Aggregations.
    # Locks to ensure that only one process is operating on the list at a time.
    # @param [ActiveFedora::Base] work the parent work
    def attach_ordered_members_to_work(work)
      acquire_lock_for(work.id) do
        work.ordered_members = work.ordered_members.to_a + ordered_members
        work.save
        ordered_members.each do |file_set|
          Hyrax.config.callback.run(:after_create_fileset, file_set, user)
        end
      end
    end
  end)
end
