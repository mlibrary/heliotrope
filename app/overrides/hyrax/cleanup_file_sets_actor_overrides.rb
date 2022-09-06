# frozen_string_literal: true

# https://tools.lib.umich.edu/jira/browse/HELIO-2092 ... and maybe other issues
Hyrax::Actors::CleanupFileSetsActor.class_eval do
  prepend(HeliotropeCleanupFileSetsActorOverrides = Module.new do
    # source: https://github.com/samvera/hyrax/blob/v2.0.0/app/actors/hyrax/actors/cleanup_file_sets_actor.rb
    def cleanup_file_sets(curation_concern)
      # From the get-go we've had orphaned FileSets from slow and brittle code in this actor
      # The stock version linked above is completely incapable of successfully deleting a Monograph...
      # with (roughly) over 200 FileSets attached
      #
      # Heliotrope changes
      # 1) actually pull the list of FileSets IDs from Solr, quickly
      # X) don't worry about the callbacks that are all about allowing a FileSet to be attached to multiple works. See:
      #    https://github.com/samvera/hydra-works/blob/a8b4e0b4b3e0f1295a06a76ce46df8b0678d4910/lib/hydra/works/models/concerns/file_set_behavior.rb#L26
      #    https://github.com/samvera/hyrax/commit/786f609ebbc9b778b14ca269cd689fed6021d2a8#diff-b953f0e618614244acf67222ab315a8a
      #    Last time I checked, there is no way to attach a FileSet to multiple works in the Hyrax UI. We never intend
      #    to do it.
      #    It's more important that Work deletion actually succeeds than to preserve unavailable PCDM functionality
      #    once you've settled on this point, 3 and 4 become possible and make this thing work
      # 2) do worry about the callbacks because they are being used to create and delete handles!!!!
      # 3) don't delete list_source in this actor. It's a slow thing to do in-line, also it's the first point of failure
      #    for us, especially in production on large Works. Either the request becomes too large or there is an
      #    unhandled runtime error
      # X) call delete rather than destroy on the FileSets, to avoid the pointless callback
      # 4) call destroy rather then delete on the FileSets, to call callbacks!!!
      # 5) do said deletion in a job to allow other actors to proceed and, ultimately, the page to reload

      # ********************************* Hyrax Version **************************************************** #
      #
      ## Destroy the list source first.  This prevents each file_set from attemping to
      ## remove itself individually from the work. If hundreds of files are attached,
      ## this would take too long.

      ## Get list of member file_sets from Solr
      # fs = curation_concern.file_sets
      # curation_concern.list_source.destroy
      ## Remove Work from Solr after it was removed from Fedora so that the
      ## in_objects lookup does not break when FileSets are destroyed.
      # ActiveFedora::SolrService.delete(curation_concern.id)
      # fs.each(&:destroy)
      # ******************************** End Hyrax Version ************************************************* #

      # Remove Work from Solr after it was removed from Fedora so that the
      # in_objects lookup does not break when FileSets are destroyed.
      ActiveFedora::SolrService.delete(curation_concern.id)
      FeaturedRepresentative.where(file_set_id: curation_concern.member_ids).destroy_all

      # Hyrax 3 HELIO-4237
      # It appears that Embargo and Lease object are now automatically being created for new Works, but
      # also that they are not being deleted with the Work. It's weird, I don't know.
      # If a Work has an Embargo or Lease, make sure we're deleting those too.
      to_delete =  curation_concern.member_ids
      to_delete << curation_concern.embargo.id if curation_concern.embargo.present?
      to_delete << curation_concern.lease.id if curation_concern.lease.present?
      # HELIO-2477 delete list_source last
      to_delete << curation_concern.list_source.id

      DestroyActiveFedoraObjectsJob.perform_later(to_delete)
    end
  end)
end
