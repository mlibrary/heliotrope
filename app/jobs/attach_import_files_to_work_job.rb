# frozen_string_literal: true

# Creates FileSets with uploaded files and their attributes and attaches them to the work.
class AttachImportFilesToWorkJob < ApplicationJob
  # @param [ActiveFedora::Base] work - the work object
  # @param [Hash<attributes>] work_attributes - a hash of work attributes a.k.a env.attributes
  # @param [Array<UploadedFile>] files - an array of files to attach
  # @param [Array<attributes>] files_attributes - an array of file attributes to apply
  def perform(work, work_attributes, files, files_attributes)
    validate_files!(files)
    user = User.find_by_user_key(work.depositor) # rubocop:disable Rails/DynamicFindBy # BUG? file depositor ignored
    work_visibility_attributes = visibility_attributes(work_attributes)
    work_permissions = work.permissions.map(&:to_hash)
    files.each_with_index do |file, i|
      actor = Hyrax::Actors::FileSetActor.new(FileSet.create, user)
      actor.create_metadata(work_visibility_attributes)
      actor.update_metadata(files_attributes[i])
      actor.create_content(file)
      actor.attach_to_work(work)
      actor.file_set.permissions_attributes = work_permissions
      file.update(file_set_uri: actor.file_set.uri)
    end
    # representative_image(env.curation_concern)
  end

  private

    # The attributes used for visibility - sent as initial params to created FileSets.
    def visibility_attributes(attributes)
      attributes.slice(:visibility, :visibility_during_lease,
                       :visibility_after_lease, :lease_expiration_date,
                       :embargo_release_date, :visibility_during_embargo,
                       :visibility_after_embargo)
    end

    def validate_files!(uploaded_files)
      uploaded_files.each do |uploaded_file|
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end
  #
  # # Currently redundant with default behavoir but left as placeholder for explicit assignment
  # def representative_image(monograph)
  #   cover_id = monograph.ordered_members.to_a.first&.id
  #   monograph.representative_id = cover_id
  #   monograph.thumbnail_id = cover_id
  #   monograph.save!
  # end
end
