# frozen_string_literal: true

class RegisterFileSetDoisActor < Hyrax::Actors::AbstractActor
  def update(env)
    # 1. If the Press is set up to auto-generate DOIs.
    # 2. If we are going from Private to Public
    # 3. If we are *not* updating/adding any file_sets
    # 4. If the Monograph already has a DOI
    # Then: create DOIs for the FileSets
    # UPDATE: 5. If there are 'eligibile' files_set that need DOIs (more than
    # just "monography" file_sets like the cover, epub, pdf_ebook or mobi)
    # see HELIO-2812

    # HELIO-2659, HELIO-2742

    # This Actor needs to be positioned really early on in the Actor stack because
    # we need to know if any FileSets are being added/updated. The actors that deal
    # with FileSets remove them from attributes like:
    # files = env.attributes.delete(:uploaded_files)
    # so in order to know if any files are added/updated, we need to do this first.
    # Once again, we *only* create DOIs if NO file_sets are being operated on in any way.
    # (Aside from permissions. If the parent changing it's permssions triggers the children
    # to also change permissions that's (probably) fine.)

    current_visibility = env.curation_concern.visibility
    next_actor.update(env) && create_dois(env, current_visibility)
  end

  private

    def create_dois(env, current_visibility)
      return true unless press_can_make_dois?(env)
      return true unless private_to_public?(current_visibility, env.attributes['visibility'])
      return true if file_sets?(env)
      return true unless monograph_has_doi?(env)
      return true if no_eligible_file_sets?(env)

      # Crossref::FileSetMetadata *may* add dois to FileSets and then send them
      # to BatchSaveJob to save them. So it's better if no other FileSet ops are happening,
      # although as mentioned there might be no way around permission saving.

      Rails.logger.info("CREATING DOIs FOR FileSets OF #{env.curation_concern.id}")
      doc = Crossref::FileSetMetadata.new(env.curation_concern.id).build
      Crossref::Register.new(doc.to_xml).post
      true
    end

    def press_can_make_dois?(env)
      Press.where(subdomain: env.curation_concern.press).first&.create_dois?
    end

    def private_to_public?(old_visibility, new_visibility)
      old_visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE && new_visibility == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end

    def file_sets?(env)
      return true if env.attributes['uploaded_files'].present?
      return true if env.attributes['import_uploaded_files_ids'].present?
      return true if env.attributes['remote_files'].present?
      false
    end

    def monograph_has_doi?(env)
      env.curation_concern.doi.present?
    end

    def no_eligible_file_sets?(env)
      # If the only FileSets a Monograph currently has are direct representatives of
      # the Monograph like the Cover or EPUB (or any book-like Fileset like a mobi or pdf_ebook)
      # then don't send anything to crossref. Those FileSets do not need DOIs
      ineligible_ids = FeaturedRepresentative.where(monograph_id: env.curation_concern.id)
                                             .where(kind: ['epub', 'pdf_ebook', 'mobi'])
                                             .map(&:file_set_id)
      ineligible_ids << env.curation_concern.representative_id

      return true if ineligible_ids.sort == env.curation_concern.member_ids.sort
    end
end
