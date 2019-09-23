# frozen_string_literal: true

module Hyrax
  # Grants edit access for the supplied user for the members attached to a work
  class GrantEditToMembersJob < ApplicationJob
    queue_as Hyrax.config.ingest_queue_name

    # @param [ActiveFedora::Base] work - the work object
    # @param [String] user_key - the user to add
    def perform(work, user_key)
      # If this is "fulcrum-system" don't bother since that's not a real user
      return if user_key == ::User.batch_user_key
      # Iterate over ids because reifying objects is slow.
      file_set_ids(work).each do |file_set_id|
        # Call this synchronously, since we're already in a job
        GrantEditJob.perform_now(file_set_id, user_key)
      end
    end

    private

      # Filter the member ids and return only the FileSet ids (filter out child works)
      # @return [Array<String>] the file set ids
      # HELIOTROPE override
      # .search_with_conditions is in AF and it produces, with a Work with many FileSet
      # a HUGE solr query that is rejected by solr with a 414 error. For smaller Works
      # this isn't a problem. With very large works with over 3000 FileSets the resulting
      # solr GET query is over 64k! Which isn't needed for heliotrope since we don't have
      # child works. Just a listing of 3000 FileSet ids is much smaller.
      # It looks like a lot of these sipity driven jobs use this AF method. We might have
      # to override them all. We'll see.
      def file_set_ids(work)
        # ::FileSet.search_with_conditions(id: work.member_ids).map(&:id)
        work.ordered_member_ids
      end
  end
end
