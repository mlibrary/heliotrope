# frozen_string_literal: true

# Creates FileSets with uploaded files and their attributes and attaches them to the work.
class AttachImportFilesToWorkJob < ApplicationJob
  # @param [ActiveFedora::Base] work - the work object
  # @param [Hash<attributes>] work_attributes - a hash of work attributes a.k.a env.attributes
  # @param [Array<UploadedFile>] files - an array of files to attach
  # @param [Array<attributes>] files_attributes - an array of file attributes to apply
  def perform(work, work_attributes, files, files_attributes) # rubocop:disable Metrics/CyclomaticComplexity
    validate_files!(files)
    user = User.find_by_user_key(work.depositor) # rubocop:disable Rails/DynamicFindBy # BUG? file depositor ignored
    work_visibility_attributes = visibility_attributes(work_attributes)
    work_permissions = work.permissions.map(&:to_hash)
    cover_noid = ''
    files.each_with_index do |file, i|
      f = FileSet.create
      actor = Hyrax::Actors::FileSetActor.new(f, user)
      actor.create_metadata(work_visibility_attributes)

      representative_kind = files_attributes[i].delete('representative_kind')
      if representative_kind == 'cover'
        cover_noid = f.id
        representative_kind = nil
      end

      actor.update_metadata(files_attributes[i])
      file.present? ? actor.create_content(file) : external_resource_label_title(f)
      actor.attach_to_work(work)
      # external resources are missing out on an asynchronous save from jobs kicked off...
      # in create_content which amazingly *need* to happen after attach_to_work.
      f.save if file.blank?
      actor.file_set.permissions_attributes = work_permissions
      file.update(file_set_uri: actor.file_set.uri) if file.present?

      next if representative_kind.blank?
      FeaturedRepresentative.where(monograph_id: work.id, file_set_id: f.id).destroy_all
      FeaturedRepresentative.create!(monograph_id: work.id, file_set_id: f.id, kind: representative_kind)
    end
    representative_image(work, cover_noid) if cover_noid.present?
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
        # we don't want a Hyrax::UploadedFile created for external resources, they're nil
        next if uploaded_file.nil?
        next if uploaded_file.is_a? Hyrax::UploadedFile
        raise ArgumentError, "Hyrax::UploadedFile required, but #{uploaded_file.class} received: #{uploaded_file.inspect}"
      end
    end

    # default behavior sets to the first FileSet but it can optionally be assigned in the CSV, which happens here
    def representative_image(monograph, cover_noid)
      monograph.representative_id = cover_noid
      monograph.thumbnail_id = cover_noid
      monograph.save!
    end

    def external_resource_label_title(file_set)
      file_set.label = file_set.external_resource_url || '< external link >'
      file_set.title = [file_set.label] if file_set.title.blank?
    end
end
