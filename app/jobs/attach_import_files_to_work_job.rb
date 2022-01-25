# frozen_string_literal: true

# Creates FileSets with uploaded files and their attributes and attaches them to the work.
class AttachImportFilesToWorkJob < ApplicationJob
  include Hyrax::Lockable

  queue_as :attach_files
  attr_reader :cover_noid, :ordered_members
  # @param [ActiveFedora::Base] work - the work object
  # @param [Hash<attributes>] work_attributes - a hash of work attributes a.k.a env.attributes
  # @param [Array<UploadedFile>] files - an array of files to attach
  # @param [Array<attributes>] files_attributes - an array of file attributes to apply
  def perform(work, work_attributes, files, files_attributes) # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    validate_files!(files)
    new_ordered_members = []
    @cover_noid = nil

    user = User.find_by_user_key(work.depositor) # rubocop:disable Rails/DynamicFindBy
    work_visibility_attributes = visibility_attributes(work_attributes)
    work_permissions = work.permissions.map(&:to_hash)

    files.each_with_index do |file, i|
      f = FileSet.create
      # actor = Hyrax::Actors::FileSetActor.new(f, user)
      # Unlike Hyrax::Actors::FileSetActor, this will not attach the file_set
      # to the ordered_members array of the work, which is super slow if
      # we have to do it FOR EACH file_set. Instead it attaches all the file_sets
      # at the end, outside of this .each_with_index loop via
      # add_ordered_members(user, work) See:
      # https://gist.github.com/geekscruff/a9ee3cbddef3e38cf51f94582f6425c6
      actor = Hyrax::Actors::FileSetOrderedMembersActor.new(f, user)
      actor.create_metadata(work_visibility_attributes)

      representative_kind = files_attributes[i].delete('representative_kind')

      actor.update_metadata(files_attributes[i])
      file.present? ? actor.create_content(file) : external_resource_label_title(f)
      actor.attach_to_work(work)

      # external resources are missing out on an asynchronous save from jobs kicked off...
      # in create_content which amazingly *need* to happen after attach_to_work.
      f.save if file.blank?
      actor.file_set.permissions_attributes = work_permissions
      file.update(file_set_uri: actor.file_set.uri) if file.present?
      new_ordered_members << actor.file_set

      add_representative(work, f, representative_kind) if representative_kind.present?
    end

    representative_image(work, @cover_noid) if @cover_noid.present?
    add_ordered_members(user, work, new_ordered_members)
  end

  private

    # Add all file_sets as ordered_members in a single action
    # HELIOTROPE: This is copied out of hyrax's AttachFilesToWorkWithOrderedMembersJob
    # which makes this job a FrankenJob(!) combination of:
    # Hyrax AttachFilesToWorkJob, Hyrax AttachFilesToWorkWithOrderedMembersJob and
    # various Heliotrope additions, mostly related to FeaturedRepresentatives, external_resources
    # and adding metadata to file_sets on ingest
    def add_ordered_members(user, work, new_ordered_members)
      actor = Hyrax::Actors::OrderedMembersActor.new(new_ordered_members, user)
      actor.attach_ordered_members_to_work(work)
      # Hyrax::Actors::OrderedMembersActor does not spawn a job. So if we're
      # here, ordered_members have been attached
      reindex_missed_filesets(work)
    end

    def reindex_missed_filesets(work)
      # In heliotrope, we index FileSets so that they know their Work in solr
      # in the 'monograph_id_ssim' field. Because we're attaching ordered_members
      # last, FileSets that were processed (Characterized, etc) *before* the Work's
      # ordered_members were attached will not have 'monograph_id_ssim' populated
      # in Solr. So we need to reindex just those FileSets (yet again).
      # This *must* be run after ordered_members are attached.
      mono_doc = ActiveFedora::SolrService.query("{!terms f=id}#{work.id}", rows: 1).first
      ids = mono_doc['ordered_member_ids_ssim']
      return if ids.blank?
      docs = ActiveFedora::SolrService.query("{!terms f=id}#{ids.join(',')}", rows: 10_000)
      ReindexJob.perform_later(docs.filter_map { |doc| doc.id if doc['monograph_id_ssim'].blank? })
    end

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        # we don't want a Hyrax::UploadedFile created for external resources, they're nil
        next if uploaded_file.nil?
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    def add_representative(work, file_set, kind)
      return if kind.blank?
      if kind == "cover"
        @cover_noid = file_set.id
        return
      end
      # these deletions match the table uniqueness constraints, should enable a failed job to re-run etc.
      FeaturedRepresentative.where(file_set_id: file_set.id).destroy_all
      FeaturedRepresentative.where(work_id: work.id, kind: kind).destroy_all
      FeaturedRepresentative.create!(work_id: work.id, file_set_id: file_set.id, kind: kind)
    end

    # We've disabled the default Hyrax behavior which sets these to the first FileSet.
    # They can optionally be assigned from the CSV 'Representative Kind' column, which happens here.
    def representative_image(monograph, cover_noid)
      acquire_lock_for(monograph.id) do
        monograph.representative_id = cover_noid
        monograph.thumbnail_id = cover_noid
        monograph.save!
      end
    end

    def external_resource_label_title(file_set)
      file_set.label = file_set.external_resource_url || '< external link >'
      file_set.title = [file_set.label] if file_set.title.blank?
    end
end
