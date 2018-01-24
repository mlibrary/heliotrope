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
      if env.curation_concern.class == FileSet
        FeaturedRepresentative.where(file_set_id: env.curation_concern.id).first.destroy
      elsif env.curation_concern.class == Monograph
        FeaturedRepresentative.where(monograph_id: env.curation_concern.id).destroy_all
      end
      true
    end
end
