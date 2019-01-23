# frozen_string_literal: true

# Responsible for removing trophies related to the given curation concern.
class FeaturedRepresentativeActor < Hyrax::Actors::AbstractActor
  # @param [Hyrax::Actors::Environment] env
  # @return [Boolean] true if destroy was successful
  def destroy(env)
    cleanup_featured_representative(env)
    next_actor.destroy(env)
  end

  private

    def cleanup_featured_representative(env)
      # Apparently this only gets called on Works, not FileSets
      # FileSet deletion is handled in the overridden hyrax FileSetController
      # See HELIO-1499
      if env.curation_concern.class == Monograph
        FeaturedRepresentative.where(monograph_id: env.curation_concern.id).destroy_all
      end
      true
    end
end
