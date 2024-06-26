# frozen_string_literal: true

class PublishJob < ApplicationJob
  queue_as :publish

  def perform(curation_concern)
    curation_concern.date_published = [Hyrax::TimeService.time_in_utc]

    # We need to make sure we're getting read_groups and write_groups inherited
    # from the monograph if this is a FileSet
    # This seems to be unstable, see HELIO-3630
    if curation_concern.is_a?(FileSet) && curation_concern&.parent.present?
      curation_concern.read_groups = curation_concern.parent.read_groups
      curation_concern.edit_groups = curation_concern.parent.edit_groups
    end

    # TODO: this is probably not how we publish in the long run
    curation_concern.visibility = 'open'

    curation_concern.save!

    # We want to avoid showing objects to users until their citable links are squared away, so setting DOIs should...
    # always come before publication. If this is a Monograph that requires automatic DOI creation for its FileSets
    # we'll do that step now.

    # NB: Triggering async jobs that loop over and save the same group of FileSets is a bad idea in ActiveFedora, see...
    # HELIO-4551, which is a home-grown problem similar to https://github.com/samvera/hyrax/issues/5827 (HELIO-4325)
    # which is why `BatchSaveJob`, called on the Monograph's FileSets here through `Crossref::FileSetMetadata.build()`...
    # _must_ be inline (`perform_now`). The save done on the same FileSets below, through the recursive call to this...
    # job can then safely be asynchronous (`perform_later`)
    maybe_create_file_set_dois(curation_concern) if curation_concern.is_a? Monograph

    # Publish all the children too
    if curation_concern.is_a?(Monograph)
      curation_concern.members.each do |member|
        PublishJob.perform_later(member)
      end
    end
  end

  # Under certain conditions, "publishing" a monograph will register
  # DOIs for some of it's FileSets.
  #
  # HELIO-2659, HELIO-2742
  #
  # See also the app/actors/register_file_set_dois_actor.rb which has
  # basically all this code in the Actor context and more as well.
  #
  # It might make sense to put this and the actor code in one place.
  # But maybe we just get rid of this PublishJob.
  # It's no longer really used in the UI (people tend to just set the monograph to public
  # on the edit page). The PublishJob is used by a rake task (or two?) but it's
  # so simple, just setting things to "open", I'm not sure how necessary it is...
  def maybe_create_file_set_dois(monograph)
    return unless Press.where(subdomain: monograph.press).first&.create_dois?
    return if monograph.doi.blank?

    doc = Crossref::FileSetMetadata.new(monograph.id).build
    Crossref::Register.new(doc.to_xml).post
  end
end
